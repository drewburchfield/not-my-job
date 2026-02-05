# Python Quality Tooling Templates

## ruff.toml

```toml
# Ruff linter + formatter config
line-length = 100

[lint]
select = [
  "E",   # pycodestyle errors
  "F",   # pyflakes
  "I",   # isort (import sorting)
  "UP",  # pyupgrade
]
ignore = []

[format]
quote-style = "double"
indent-style = "space"
```

### Install command

```bash
pip install ruff
```

Or if using `pyproject.toml` with a build tool:

```bash
uv add --dev ruff
```

Check for `uv.lock` to determine if the project uses `uv`.

## pyright Config

Add to `pyproject.toml` under `[tool.pyright]`:

```toml
[tool.pyright]
typeCheckingMode = "basic"
pythonVersion = "3.11"
```

If `pyproject.toml` does not exist, create a minimal one:

```toml
[project]
name = "<project-name>"
version = "0.1.0"
requires-python = ">=3.11"

[tool.pyright]
typeCheckingMode = "basic"
pythonVersion = "3.11"
```

### Install command

```bash
pip install pyright
```

Or with uv:

```bash
uv add --dev pyright
```

## pytest Config

Add to `pyproject.toml` if no test config exists:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
```

### Install command

```bash
pip install pytest
```

## Quality Gate Commands

| Gate | Command |
|---|---|
| Type check | `pyright` |
| Lint | `ruff check .` |
| Format | `ruff format --check .` |

## Package Manager Detection

Check in this order:
1. `uv.lock` exists: use `uv`
2. `Pipfile` exists: use `pipenv`
3. `poetry.lock` exists: use `poetry`
4. Default: `pip`
