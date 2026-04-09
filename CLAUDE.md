# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a static single-page personal portfolio site deployed via GitHub Pages (`jurri.github.io`). There is no build step, no package manager, and no framework — the entire site lives in `index.html` with all CSS and JavaScript inline.

## Development

Open `index.html` directly in a browser, or serve it locally:

```bash
python3 -m http.server 8080
```

Deploy by pushing to the `main` branch — GitHub Pages publishes automatically.

## Architecture

Everything is in a single file ([index.html](index.html)):

- **CSS** — custom properties (`--var-name`) defined in `:root` drive the entire dark theme. Card accent colors are set via per-card CSS custom property overrides (e.g. `--card-accent`, `--tag-bg`, `--tag-color`).
- **Bilingual (EN/DE)** — elements carry `data-lang-en` or `data-lang-de` attributes. Adding `lang-de` to `<body>` flips visibility via CSS. `setLang()` in the script block handles toggling, persists to `localStorage`, and auto-detects from `navigator.language`.
- **Scroll reveal** — sections with `.reveal` are observed by an `IntersectionObserver`; the `.visible` class triggers the CSS transition.
- **Sections** — Hero → About → Skills → Projects → Contact → Footer, each in its own `<section>` with a matching `id`.

## Content patterns

- **Adding a project card**: copy the existing `.project-card` block inside `#projects .projects-grid` and fill in the details. Use `data-lang-en` / `data-lang-de` spans for bilingual text.
- **Adding a skill card**: copy a `.skill-card` block in `#skills .skills-grid`. Assign one of the existing modifier classes (`backend`, `frontend`, `database`, `devops`, `admin`) to get the correct accent color, or add a new modifier with its own `--card-accent`, `--tag-bg`, and `--tag-color` values.
- **Social links**: update the `<a>` tags in `#contact .social-links`.
- **All user-facing text** must have both a `data-lang-en` and a `data-lang-de` sibling to keep the language toggle working correctly.