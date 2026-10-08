---
title: "Detecting RDP Brute-Force Attacks with Splunk"
date: 2026-10-08 09:00:00 +0200
categories: [Detection Engineering & SOC, SPL]
tags: [blue-team, splunk, detection-engineering, rdp, windows, soc]
description: "How RDP brute-force attacks work, what they leave behind in Windows event logs, and how to detect them reliably in Splunk — with a working correlation search."
---

## What is an RDP brute-force attack?

A Remote Desktop Protocol (RDP) brute-force attack floods an RDP service with
repeated login attempts, systematically trying passwords — often weak, reused,
or default ones — until a valid combination is found. It's one of the most
common ways attackers gain *initial access* to a Windows host, especially when
port **3389** is exposed to the Internet or reachable across a flat internal
network.

Unlike post-exploitation techniques (Golden Ticket, DCSync, Pass-the-Hash),
a brute force needs **no prior access and no prerequisites** — that's exactly
why it's attractive to attackers. It's the front door, not something you reach
after already owning the domain.

In MITRE ATT&CK terms this maps to **T1110 – Brute Force** combined with
**T1021.001 – Remote Services: Remote Desktop Protocol**.

---

## How the attack works

Understanding the attacker's workflow is what lets us map each step to the
telemetry it produces. Here's the typical sequence.

**1. Find exposed RDP hosts**

```bash
nmap -p 3389 --open -oG hosts_rdp.txt 10.0.0.0/24
```

**2. Confirm the service responds (optional)**

```bash
xfreerdp /v:10.0.0.15 /u:invalid /p:invalid
```

**3. Spray credentials**

```bash
hydra -L users.txt -P passwords.txt rdp://10.0.0.15 -t 4 -f
```

- `-L` user list, `-P` password list
- `-t 4` concurrent threads (kept low — RDP is slow and high thread counts cause
  failures and lockouts)
- `-f` stop on first success

**4. Log in with the discovered credentials**

```bash
xfreerdp /v:10.0.0.15 /u:Administrator /p:'<password>'
```

From here the attacker has an interactive session and can drop tooling, execute
payloads, or move laterally.

> The interesting part for us isn't the commands — it's the **trail they leave**.

---

## What it looks like in the logs

Every one of those login attempts generates a Windows Security event on the
target host:

| Event ID | Meaning | Logon Type |
|----------|---------|------------|
| **4625** | Failed logon  | **10** (RemoteInteractive = RDP) |
| **4624** | Successful logon | **10** (RemoteInteractive = RDP) |

The signature of a brute force is simple to describe: **a large burst of 4625
(failures) from a single source, optionally followed by a 4624 (success)** for
the same account from the same source. The follow-up success is the "game over"
signal — it means the attack worked.

A couple of field notes before the query:

- The source IP field name depends on your Windows add-on / CIM mapping. With
  `Splunk_TA_windows` it's often `Source_Network_Address` or normalized to `src`.
  Adjust `src_ip` below to match your environment.
- `Account_Name` can appear twice in a 4625 (the subject and the target). Make
  sure you're keying on the *target* account.

---

## Detecting it in Splunk

### Rule 1 — Failure bursts (early warning)

Start simple: flag any source hammering an account with failed RDP logons.

```spl
index=main sourcetype="WinEventLog:Security" EventCode=4625 LogonType=10
| bin _time span=5m
| stats count AS failures
        values(dest) AS dest
        BY _time, src_ip, Account_Name
| where failures > 10
| sort - failures
```

Binning into 5-minute windows is important: without it you'd aggregate failures
across days and miss the "fast and loud" pattern that actually distinguishes an
attack from a forgetful user.

### Rule 2 — Successful brute force (high confidence)

This is the one that matters. It correlates failures **and** a later success
for the same `src_ip` + `Account_Name` in a single pass — no fragile join, and
`_time` is handled correctly.

```spl
index=main sourcetype="WinEventLog:Security" (EventCode=4625 OR EventCode=4624) LogonType=10
| stats
    count(eval(if(EventCode=4625,1,null())))        AS failures
    count(eval(if(EventCode=4624,1,null())))        AS successes
    earliest(eval(if(EventCode=4625,_time,null()))) AS first_fail
    latest(eval(if(EventCode=4625,_time,null())))   AS last_fail
    latest(eval(if(EventCode=4624,_time,null())))   AS success_time
    BY src_ip, Account_Name
| where failures > 10 AND successes > 0 AND success_time > first_fail
| convert ctime(first_fail) ctime(last_fail) ctime(success_time)
| table first_fail, last_fail, success_time, src_ip, Account_Name, failures, successes
```

The condition `success_time > first_fail` catches a success landing anywhere
inside the attack window. Tighten it to `success_time >= last_fail` if you only
want successes that follow the *entire* burst.

---

## Mitigations

Detecting the attack is half the job. Reduce the attack surface so the brute
force has nothing to chew on:

- **Don't expose 3389 to the Internet.** Put RDP behind a VPN or an RD Gateway.
- **Enforce Network Level Authentication (NLA).**
- **Account lockout policy** — lock after a small number of failed attempts.
- **Strong, unique passwords + MFA** on anything reachable remotely.
- **Restrict who can log on via RDP** (dedicated admin groups, not Domain Users).
- **Rename/limit the local Administrator account** and monitor it closely.

---

## Tuning and false positives

Detection is nothing without tuning. Expect these benign triggers:

- **Jump boxes / admin workstations** that legitimately RDP into many servers —
  allowlist their source IPs.
- **Expired passwords and account lockout storms** — a user whose saved
  credential went stale can rack up dozens of 4625s with no malice.
- **Vulnerability scanners and monitoring tools** hitting 3389.
