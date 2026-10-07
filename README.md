# poisonlylo.github.io

Blog technique cyber en anglais (SOC / Detection Engineering) construit avec [Jekyll](https://jekyllrb.com/) et le thème [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy), publié sur GitHub Pages par GitHub Actions à chaque push sur `main`.

## Sommaire

- [Structure du site](#structure-du-site)
- [À personnaliser avant la mise en ligne](#à-personnaliser-avant-la-mise-en-ligne)
- [Lancer le site en local](#lancer-le-site-en-local)
- [Ajouter un article](#ajouter-un-article)
- [Déployer](#déployer)

## Structure du site

| Menu latéral | Fichier | Contenu |
| ------------ | ------- | ------- |
| Accueil | `index.html` | Derniers articles |
| Infra & Archi | `_tabs/infra.md` | Articles de la catégorie `Infra & Architecture` |
| Détection & SOC | `_tabs/detection.md` | Articles de la catégorie `Detection Engineering & SOC` |
| Writeups | `_tabs/writeups.md` | Articles de la catégorie `Writeups` |
| Articles | `_tabs/articles.md` | Articles de la catégorie `Articles` (un peu de tout) |
| Tags, Archives | `_tabs/*.md` | Pages natives Chirpy |
| À propos | `_tabs/about.md` | Présentation + liens |

Autres fichiers utiles :

```text
_config.yml                 Configuration principale (titre, URL, langue, réseaux...)
_data/contact.yml           Icônes de contact en bas du menu (GitHub, LinkedIn, email, RSS)
_data/locales/en.yml        Titres des onglets de section (à mettre à jour si vous renommez un onglet)
_includes/footer.html       Pied de page sans la mention « Powered by Jekyll with Chirpy »
_layouts/section.html       Gabarit des pages de section (liste les articles d'une catégorie)
_includes/metadata-hook.html  Mode sombre par défaut (le bouton clair/sombre reste disponible)
_includes/language-alias.html Libellés des blocs de code (ajout de SPL et PowerShell)
_plugins/rouge-spl.rb       Coloration syntaxique du SPL (Splunk)
_posts/                     Les articles (un fichier Markdown par article)
_templates/                 Modèles d'articles vides, un par section (non publiés)
assets/img/posts/<slug>/    Les images, un sous-dossier par article
```

Fonctionnalités natives de Chirpy déjà actives : recherche, table des matières, coloration syntaxique, flux RSS (`/feed.xml`), PWA. Les commentaires et les analytics sont désactivés.

## À personnaliser avant la mise en ligne

Tous les champs à modifier sont marqués **`[À PERSONNALISER]`** dans le code. Pour les retrouver :

```bash
git grep -n "À PERSONNALISER"
```

| Fichier | Champ |
| ------- | ----- |
| `_config.yml` | `title`, `tagline`, `avatar`, `social_preview_image` (nom, LinkedIn et GitHub déjà renseignés ; pas d'email public) |
| `_tabs/about.md` | Texte de présentation et liens |
| `assets/img/avatar.svg` | Avatar provisoire : déposez votre photo (ex. `assets/img/avatar.jpg`) et mettez à jour `avatar` dans `_config.yml` |

> `url` doit valoir `https://<pseudo>.github.io` (sans `/` final) et le dépôt doit s'appeler `<pseudo>.github.io`.

## Lancer le site en local

### Prérequis

- **Ruby 3.x** avec les outils de compilation
  - Windows : [RubyInstaller](https://rubyinstaller.org/) version *with Devkit*, puis `ridk install` (option 3)
  - macOS : `brew install ruby`
  - Linux / WSL : `sudo apt install ruby-full build-essential zlib1g-dev`
- **Bundler** : `gem install bundler`
- **Git**

### Installation et serveur de développement

```bash
bundle install
```

```bash
bundle exec jekyll serve --livereload
```

Le site est disponible sur <http://127.0.0.1:4000>. Les modifications des articles sont prises en compte à chaud ; une modification de `_config.yml` nécessite de relancer la commande.

Un script fourni par le starter fait la même chose (Linux / macOS / WSL) : `bash tools/run.sh`.

### Tester le build comme en production

```bash
JEKYLL_ENV=production bundle exec jekyll build
```

```bash
bundle exec htmlproofer _site --disable-external
```

Ou en une fois : `bash tools/test.sh`.

## Ajouter un article

### Méthode simple : Pages CMS (interface web)

Le fichier `.pages.yml` configure [Pages CMS](https://pagescms.org), un éditeur web connecté au dépôt GitHub.

**Une seule fois** : ouvrir <https://app.pagescms.org>, se connecter avec GitHub, installer l'application GitHub **uniquement sur le dépôt `poisonlylo.github.io`** (« Only select repositories »).

**Ensuite** : *Posts → Add an entry*, remplir le titre, la date, la section, les tags, le résumé et le contenu (images par glisser-déposer, rangées dans `assets/img/posts/`), puis **Save**. Chaque sauvegarde crée un commit sur `main` et GitHub Actions republie le site en 1 à 2 minutes.

> Après une sauvegarde, vérifiez le rendu en ligne : l'éditeur visuel peut réécrire certaines syntaxes propres à Chirpy (`{: .prompt-tip }`, `{: file="..." }`). Pour ces cas, éditez le fichier Markdown directement.

### Méthode manuelle (Markdown)

1. Copiez le modèle de la section voulue depuis `_templates/` vers `_posts/` et renommez-le en **`AAAA-MM-JJ-titre-en-minuscules.md`** (la partie après la date devient l'URL : `/posts/titre-en-minuscules/`).
2. Complétez le front matter. Le premier élément de `categories` doit être **une des quatre catégories principales** en premier élément de `categories` (orthographe exacte : c'est elle qui range l'article dans la bonne section du menu) :

```yaml
---
title: "Titre de l'article"
date: 2026-10-07 18:00:00 +0200
categories: [Detection Engineering & SOC, SPL]          # [catégorie principale, sous-catégorie]
tags: [spl, mitre-attack, t1059]                        # en minuscules
description: Résumé affiché sur l'accueil et dans les métadonnées SEO.
media_subpath: /assets/img/posts/titre-en-minuscules    # dossier des images de l'article
image:                                                  # optionnel : image d'aperçu
  path: apercu.png
  alt: Description de l'image
---
```

| Catégorie principale | Plan de l'article | Modèle |
| -------------------- | ----------------- | ------ |
| `Infra & Architecture` | Context → Architecture → Deployment → Result | `_templates/infra.md` |
| `Detection Engineering & SOC` | ATT&CK technique → Required logs → SPL query → False positives → Response | `_templates/detection.md` |
| `Writeups` | Context → Challenge → Approach → Solution → What I learned | `_templates/writeup.md` |
| `Articles` | Libre | `_templates/article.md` |

3. **Images** : créez `assets/img/posts/<titre-en-minuscules>/` et référencez les images par leur seul nom grâce à `media_subpath` :

```markdown
![Schéma réseau](schema.png){: w="800" h="450" }
_Légende affichée sous l'image_
```

4. **Code** : utilisez les blocs Markdown avec le nom du langage, par exemple `spl`, `yaml`, `bash`, `powershell`. Ajoutez `{: file="chemin/du/fichier" }` juste après le bloc pour afficher un nom de fichier.

> Dans un bloc de code, toute syntaxe `{{ ... }}` (Ansible, Jinja, Go templates...) est interprétée par Jekyll. Entourez le bloc de `{% raw %}` et `{% endraw %}`.

5. **Encadrés** Chirpy : ajoutez `{: .prompt-tip }`, `{: .prompt-info }`, `{: .prompt-warning }` ou `{: .prompt-danger }` sous une citation `>`.

Un article daté dans le futur n'est pas publié. Pour un brouillon, placez le fichier sans date dans un dossier `_drafts/` et prévisualisez-le avec `bundle exec jekyll serve --drafts`.

## Déployer

Le déploiement est automatique via `.github/workflows/pages-deploy.yml` : chaque push sur `main` build le site, vérifie les liens internes (`htmlproofer`) puis le publie.

**Première mise en ligne (une seule fois)** :

1. Sur GitHub, dans le dépôt : **Settings → Pages → Build and deployment → Source : GitHub Actions**.
2. Poussez la branche :

```bash
git push origin main
```

3. Suivez le build dans l'onglet **Actions** ; le site est ensuite en ligne sur `https://poisonlylo.github.io`.

**Ensuite**, publier un article = commit + push :

```bash
git add _posts assets/img/posts
```

```bash
git commit -m "Nouvel article : titre"
```

```bash
git push
```

## Crédits

Thème [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) (licence MIT), via [chirpy-starter](https://github.com/cotes2020/chirpy-starter).
