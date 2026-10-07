---
title: "Detection: rule name (T0000.000)"
date: 2026-01-01 18:00:00 +0100
categories: [Detection Engineering & SOC, SPL]
tags: [spl, mitre-attack]
description: One-sentence summary shown on the home page and in SEO metadata.
media_subpath: /assets/img/posts/post-slug
---

## ATT&CK technique

| Field | Value |
| ----- | ----- |
| Tactic | |
| Technique | [`T0000.000`](https://attack.mitre.org/techniques/T0000/000/) |
| Platform | |
| Severity | |

## Required logs

| Source | Event | Key field |
| ------ | ----- | --------- |
| | | |

## SPL query

```spl
index=main sourcetype=...
| stats count by host
```

## False positives

## Response
