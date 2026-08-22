# jurri.github.io
jurri.github.io

## created
202604091632

## Project sync

The portfolio project cards are generated from repositories that contain `.github/project.yml`.
Run the workflow `Sync portfolio projects` manually or let the daily schedule update `index.html`.

For private repositories, add a repository secret named `PROJECT_SYNC_TOKEN` with read access to the
repositories that should be scanned. Without that secret, the workflow scans public repositories for
the configured owner.

Use `.github/project.example.yml` as the template for project metadata.
