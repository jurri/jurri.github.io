# Repository Guidelines

## Project Structure & Module Organization

This repository is a static GitHub Pages portfolio site. The public site is implemented in [index.html](/var/www/html/jurri.github.io/index.html), with HTML, CSS, and JavaScript kept inline. There is no `src/`, package manager, framework, or generated build output.

Key files:

- `index.html` - complete single-page site.
- `README.md` - minimal project metadata.
- `CLAUDE.md` - repository-specific implementation notes for agents.

When adding content, keep the existing section order: Hero, About, Skills, Projects, Contact, Footer. Project and skill entries should follow the existing card markup patterns.

## Build, Test, and Development Commands

No build step is required. Open `index.html` directly in a browser for quick checks.

Use a local static server when testing browser behavior, links, or storage:

```bash
python3 -m http.server 8080
```

Then visit `http://localhost:8080`.

Deployment is handled by GitHub Pages. Push changes to `main`; Pages publishes the static files automatically.

## Coding Style & Naming Conventions

Use 4-space indentation in HTML, CSS, and JavaScript to match the existing file. Keep CSS custom properties in `:root` using the `--name` pattern, and prefer existing variables before introducing new colors or spacing values.

Class names use lowercase kebab-case, for example `.project-card`, `.skills-grid`, and `.lang-toggle`. JavaScript functions use camelCase, such as `setLang()`.

All visible text must remain bilingual: add paired `data-lang-en` and `data-lang-de` elements so the language toggle continues to work.

## Testing Guidelines

There is no automated test suite. Manually verify changes in a browser at desktop and mobile widths. Check language switching, smooth scrolling, reveal animations, project links, social links, and console errors.

For visual edits, compare both English and German states before committing.

## Commit & Pull Request Guidelines

Recent commits use short imperative summaries with uppercase prefixes, such as `FIX: social links` and `TASK: ...`. Follow that style when practical.

Pull requests should include a concise description, screenshots for visual changes, affected sections, and any manual checks performed. Link related issues when available.

## Agent-Specific Instructions

Before editing, read `CLAUDE.md` for current repository behavior and content patterns. Do not add build tooling, dependencies, or frameworks unless the task explicitly requires it.
