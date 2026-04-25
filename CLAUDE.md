# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

ETL pipeline that pulls NHL game data from the NHL public API, stores raw JSON in Supabase (PostgreSQL) and S3, then transforms it with dbt. Two independent components: `ingestion/` (AWS Lambda) and `transform/` (dbt).

## Commands

Both components use **uv** for dependency management.

### Ingestion

```bash
cd ingestion && uv sync           # install deps
./scripts/ingestion/docker/build.sh   # build Docker image
./scripts/ingestion/docker/run.sh nhl_api_s3.lambda_handler        # run S3 handler locally
./scripts/ingestion/docker/run.sh nhl_api_supabase.lambda_handler   # run Supabase handler locally
./scripts/ingestion/docker/push.sh    # push image to ECR
```

Invoke locally after container starts:
```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" -d @ingestion/test_event.json
```

### Transform (dbt)

```bash
cd transform && uv sync           # install deps
./scripts/transform/docker/run.sh run      # run all models
./scripts/transform/docker/run.sh test     # run tests
./scripts/transform/docker/run.sh build    # run + test
./scripts/transform/docker/run.sh compile  # compile SQL only
```

Or directly with dbt after `uv sync`:
```bash
cd transform && dbt deps && dbt run
dbt test
dbt run --select <model_name>     # run a single model
```

### Infrastructure

```bash
./scripts/infra/deploy.sh         # deploy/update CloudFormation stack
```

### Linting

Both components use **ruff** (line-length: 100, single quotes). Run via `uv run ruff check` or `uv run ruff format` from the respective component directory.

## Architecture

### Data Flow

1. **EventBridge** triggers Lambda daily at 1 PM UTC (8 AM EST)
2. **Lambda** (`ingestion/`) fetches yesterday's games from the NHL API:
   - Schedule: `https://api-web.nhle.com/v1/schedule/{date}`
   - Play-by-play per game: `https://api-web.nhle.com/v1/gamecenter/{game_id}/play-by-play`
3. **Raw storage**: JSON written to S3 (partitioned `game_data={date}/game_id={id}.json`) and/or Supabase (`raw_api_data.game_data` table)
4. **dbt** (`transform/`) reads from Supabase and produces flattened analytic tables

### Ingestion Component (`ingestion/`)

Two Lambda handlers share the same Docker image but have different entry points:
- `nhl_api_s3.py` → stores to S3
- `nhl_api_supabase.py` → stores to Supabase via REST API (uses `Prefer: resolution=merge-duplicates` for idempotent retries)

Shared logic lives in `ingestion/lib/`:
- `nhl_api.py` — fetches and assembles game data
- `s3_uploader.py` — boto3 S3 put
- `supbase_uploader.py` — Supabase REST client

Credentials: `.env` file locally; AWS Parameter Store (SSM) in Lambda production.

### Transform Component (`transform/`)

dbt project with two model layers:
- `models/staging/stg_games.sql` — flattens the raw `event` JSONB blob from Supabase into a wide row per game
- `models/base/` — further normalized tables: `games`, `plays` (unnested array), `teams`, `roster` (unnested array)

Uses `dbt_utils` for surrogate key generation. Configured for both PostgreSQL (Supabase) and DuckDB profiles.

### Infrastructure (`infra/cloudformation/resources.yml`)

Single CloudFormation template provisions: S3 bucket, ECR repository, two Lambda functions, EventBridge rules, and IAM roles.

### CI/CD (`.github/workflows/`)

- `ci.yml` — on non-main push: build Docker image, tag with commit SHA + `ci`, push to ECR, deploy CloudFormation
- `cd.yml` — on main push: re-tag the CI image as `prod` and push to ECR

## Environment Setup

Create a `.env` file at the repo root with:
```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=...
SUPABASE_URL=...
SUPABASE_SECRET=...
```
