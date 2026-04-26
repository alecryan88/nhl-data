---
name: dbt-transform
description: Write or review a dbt SQL model following project conventions: CTEs over subqueries, descriptive naming, and CTE-level comments.
trigger: /dbt-transform
args: "[model name or description]"
---

## Function

Write or review a dbt SQL model following the conventions for this project.

## Style Rules

### Structure
- **Always use CTEs, never subqueries.** Every intermediate result must be a named CTE at the top of the file.
- End each model with a final `SELECT *` (or explicit column list) from the last CTE — do not inline logic in the final select.
- Use `with` at the top of the file; each CTE on its own block separated by a blank line.

### Naming
- CTE names: lowercase snake_case, descriptive of what the CTE produces (e.g. `filtered_games`, `ranked_plays`, `player_totals`). Avoid vague names like `cte1`, `temp`, `data`.
- Column aliases: lowercase snake_case, self-explanatory without needing comments (e.g. `total_goals`, `game_date`, `team_abbrev`).
- Model file names: match the naming tier (`stg_`, `base_`, `mart_` prefix per layer).

### Comments
- Add a single-line SQL comment (`--`) immediately above each CTE describing what it does in plain English.
- Comments should explain *why* or *what the CTE produces*, not echo the SQL mechanically. Example:
  ```sql
  -- filter to regular season games only, excluding pre-season and playoffs
  regular_season_games as (
      select * from source_games where game_type = 2
  )
  ```
- Do NOT comment every column or add block comments unless the logic is genuinely non-obvious.

### dbt Conventions
- Reference upstream models with `{{ ref('model_name') }}` and sources with `{{ source('schema', 'table') }}`.
- Use `{{ dbt_utils.generate_surrogate_key([...]) }}` for surrogate keys.
- Staging models (`stg_`) should do one thing: flatten/cast raw source data, no business logic.
- Base models (`base_`) normalize staging into entity-grain tables.
- Mart models (`mart_`) join base tables and apply business logic for analysis.

## Steps

When writing a new model:

1. **Clarify the grain** — confirm what one row represents before writing any SQL.
2. **Identify sources** — list upstream `ref()` or `source()` inputs.
3. **Sketch the CTE chain** — plan each transformation step as a named CTE before writing the body.
4. **Write the model** — apply all style rules above.
5. **Add a schema entry** — if a `schema.yml` exists in the same folder, add a model block with `description` and column descriptions for any output columns that aren't obvious.

When reviewing an existing model, flag any of:
- Subqueries that should be CTEs
- Vague CTE or column names
- Missing CTE comments
- Business logic in a staging model
- Missing `ref()`/`source()` usage (raw table names)

## Example Template

```sql
with

-- pull raw game data from the Supabase source table
source as (
    select * from {{ source('raw_api_data', 'game_data') }}
),

-- unnest the event JSONB blob into a flat row per game
flattened as (
    select
        (event->>'id')::int         as game_id,
        (event->>'season')::int     as season,
        (event->>'gameType')::int   as game_type,
        (event->>'gameDate')::date  as game_date
    from source
),

-- restrict to regular season games (game_type = 2)
regular_season as (
    select * from flattened where game_type = 2
)

select * from regular_season
```
