---
name: lint
description: Run ruff check and format on ingestion/ and transform/ components. Accepts an optional --fix arg to auto-fix violations.
trigger: /lint
args: "[--fix]"
---

## Function

Run ruff linting and format checks across both Python components of this repo.

### Steps

1. **Determine mode** based on args:
   - `--fix` → run `ruff check --fix` and `ruff format` (mutates files)
   - no arg (default) → run `ruff check` and `ruff format --check` (read-only)

2. **Run ruff on `ingestion/`**:
   ```bash
   cd ingestion && uv run ruff check . && uv run ruff format --check .
   # or with --fix:
   cd ingestion && uv run ruff check --fix . && uv run ruff format .
   ```

3. **Run ruff on `transform/`**:
   ```bash
   cd transform && uv run ruff check . && uv run ruff format --check .
   # or with --fix:
   cd transform && uv run ruff check --fix . && uv run ruff format .
   ```

4. **Report results**:
   - If all clean: confirm both components passed with no violations.
   - If violations found: show the ruff output per component. If in check mode, suggest re-running with `--fix` for auto-fixable issues.
   - If `--fix` was used: summarize how many files were modified.

### Notes
- Always run from the repo root using `cd <component>` before each command — do not use absolute paths.
- `transform/` only has Python config in `pyproject.toml`; there are no `.py` files to lint outside of dbt packages. Ruff will exit cleanly with no output if there's nothing to check — that's expected.
- Both components use ruff with `line-length = 100` and `quote-style = "single"` (ingestion only explicitly sets quote style, but both share the same line-length config).
