# not-my-job

This repo is a **marketplace registry** for Claude Code plugins. It does not contain plugin source code.

## Repository structure

- `.claude-plugin/marketplace.json` - The registry manifest listing all plugins
- `plugins/` - **Gitignored.** Contains cloned plugin repos for local development. These are independent git repos with their own remotes (e.g., `github.com/drewburchfield/<plugin-name>`), not submodules.
- `cache/` - **Gitignored.** Local tooling artifacts (e.g., `projects.json`). Never tracked.

## Release recipe (plugin + marketplace ship in concert)

1. In `plugins/<name>/` (its own repo): bump `.claude-plugin/plugin.json` version, every `skills/*/SKILL.md` frontmatter `version:`, the nested dev `.claude-plugin/marketplace.json`, the README version line, and date the CHANGELOG entry.
2. Commit there, tag `v<X.Y.Z>`, push branch + tags to the plugin's remote (default branch is usually `main`).
3. In this repo: bump `metadata.version` in `.claude-plugin/marketplace.json` and the plugin's pinned `version`, commit `chore: marketplace <M.M.P>, <plugin> <X.Y.Z> (<gist>)`, push `master`.

Never release one side without the other; the marketplace pin must always point at a pushed plugin tag.

## Important

- **Never treat `plugins/` as part of this repo.** The directory is gitignored. Each subdirectory is its own standalone git repo.
- **Commits and pushes inside `plugins/<name>/` go to that plugin's remote**, not to this marketplace repo.
- **Do not create or modify files in `plugins/` expecting them to be tracked here.**
