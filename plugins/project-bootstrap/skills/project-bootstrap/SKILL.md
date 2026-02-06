---
name: project-bootstrap
description: Auto-detect project language, set up quality tooling (ESLint, Prettier, ruff, pyright), configure stop hooks for quality gates, and manage plugin selection. Use when bootstrapping a new or existing project with standard quality infrastructure.
---

# Project Bootstrap

Bootstrap a project with language-appropriate quality tooling, stop hooks, and plugin configuration. Run this once per project to establish a consistent quality baseline.

## Workflow

Execute these phases in order. Confirm with the user before making changes in each phase.

### Phase 1: Language Detection

Detect the project language by checking for marker files in the project root:

| Marker File | Language |
|---|---|
| `package.json` | Node.js (check `tsconfig.json` to distinguish TS vs JS) |
| `pyproject.toml` or `setup.py` | Python |
| `go.mod` | Go |

Steps:
1. Use Glob to check for these marker files in the current working directory
2. If `package.json` exists, also check for `tsconfig.json` to determine TypeScript vs JavaScript
3. Report the detected stack to the user: "Detected: TypeScript/Node.js project" (or similar)
4. If no markers found, ask the user what language this project uses via AskUserQuestion

### Phase 2: Quality Tooling Setup

Check what quality tools are already present and offer to install what is missing. Read the appropriate reference file for templates:

- **TypeScript/Node**: Read `references/typescript-setup.md` for config templates
- **Python**: Read `references/python-setup.md` for config templates

For each missing tool:
1. Show the user what will be created/installed
2. Use AskUserQuestion to confirm (offer "Install all" as the first option)
3. Write config files and run install commands

**TypeScript/Node checklist:**
- [ ] `tsconfig.json` (if missing)
- [ ] `eslint.config.mjs` (ESLint flat config with TypeScript plugin)
- [ ] `.prettierrc` (Prettier config)
- [ ] Dev dependencies: `eslint`, `@eslint/js`, `typescript-eslint`, `prettier`

**Python checklist:**
- [ ] `ruff.toml` (linter + formatter config)
- [ ] pyright config in `pyproject.toml` (basic type checking)
- [ ] pytest config in `pyproject.toml` (if not present)

**Go:** Skip quality tooling setup. Go has built-in tooling (`go vet`, `gofmt`). Just note the quality gate commands.

### Phase 3: Stop Hook

The plugin bundles a Stop hook that enforces quality gates. Explain to the user:

> "A stop hook will run automatically when Claude finishes working. It checks for lint errors, type errors, and formatting issues before the session completes. If issues are found, Claude will fix them before stopping."

The hook is pre-configured in this plugin's `hooks/` directory. It reads `.claude/project-meta.json` to know which quality commands to run. No user action needed here beyond acknowledgment.

**Trust boundary note:** The stop hook runs commands from `.claude/project-meta.json` via `eval`. This file is written by the bootstrap skill and should be treated as trusted project configuration. Users should review `project-meta.json` if they clone an unfamiliar repository that already contains one.

### Phase 4: Plugin Picker

Present the user with a list of currently installed/available plugins. Use AskUserQuestion with multiSelect to let them choose which plugins to enable for this project.

Steps:
1. Read `~/.claude/settings.json` and look for the `enabledPlugins` array to find installed plugins
2. Present them as options via AskUserQuestion (multiSelect: true)
3. Write selected plugins to `.claude/settings.json` (project-level, in the working directory) under `enabledPlugins`

If the project uses MCP servers (check for `.mcp.json` or `mcp` key in settings), also suggest setting `ENABLE_TOOL_SEARCH` in the project environment.

### Phase 5: Write Project Meta

Write `.claude/project-meta.json` with the detected configuration:

```json
{
  "language": "<detected language>",
  "qualityGates": {
    "typeCheck": "<type check command>",
    "lint": "<lint command>",
    "format": "<format check command>"
  },
  "bootstrapVersion": "<version from plugin.json>",
  "bootstrappedAt": "<current date YYYY-MM-DD>"
}
```

**Language-specific commands:**

TypeScript/Node:
- typeCheck: `npx tsc --noEmit`
- lint: `npx eslint .`
- format: `npx prettier --check .`

Python:
- typeCheck: `pyright`
- lint: `ruff check .`
- format: `ruff format --check .`

Go:
- typeCheck: `go vet ./...`
- lint: `go vet ./...`
- format: `test -z "$(gofmt -l .)"`

Run `date +%Y-%m-%d` to get the current date for `bootstrappedAt`. Read the plugin's `.claude-plugin/plugin.json` to get the current version for `bootstrapVersion`.

### Phase 6: Project CLAUDE.md

Generate or append to the project's `CLAUDE.md` file with a quality gates section. Use the commands from the `project-meta.json` written in Phase 5:

```markdown
## Quality Gates

This project uses automated quality gates. The following checks run on every Claude stop:

- **Type check**: `<typeCheck command from meta>`
- **Lint**: `<lint command from meta>`
- **Format check**: `<format command from meta>`

Fix all quality gate errors before considering work complete.
```

If `CLAUDE.md` already exists, append the quality gates section. Do not overwrite existing content.

## Completion

After all phases complete, print a summary:

```
Bootstrap complete:
- Language: <language>
- Quality tools: <list of installed tools>
- Stop hook: active (runs on every Claude stop)
- Enabled plugins: <list>
- Meta: .claude/project-meta.json
```
