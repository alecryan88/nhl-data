# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

ETL pipeline that pulls NHL game data from the NHL public API, stores raw JSON in Supabase (PostgreSQL) and S3, then transforms it with dbt. Four components: `ingestion/` (AWS Lambda), `transform/` (dbt), `lineage/` (OpenLineage transport), and `airflow/` (local orchestration).

## Commands

All Python components use **uv** for dependency management.

### Ingestion

```bash
cd ingestion && uv sync                    # install deps
ENV=dev ./scripts/ingestion/docker/build.sh   # build Docker image
ENV=dev ./scripts/ingestion/docker/run.sh nhl_api_s3.lambda_handler        # run S3 handler locally
ENV=dev ./scripts/ingestion/docker/run.sh nhl_api_supabase.lambda_handler   # run Supabase handler locally
ENV=ci  ./scripts/ingestion/docker/push.sh    # push image to ECR (ci or prod)
```

Invoke locally after container starts:
```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" -d @ingestion/test_event.json
```

Run once for a specific date (used by Airflow):
```bash
./scripts/ingestion/run_local.sh 2024-11-01
```

### Transform (dbt)

```bash
cd transform && uv sync           # install deps
./scripts/transform/docker/run.sh run      # run all models
./scripts/transform/docker/run.sh test     # run tests
./scripts/transform/docker/run.sh build    # run + test
./scripts/transform/docker/run.sh compile  # compile SQL only
```

Run without AWS credentials (used by Airflow):
```bash
./scripts/transform/run_local.sh run
./scripts/transform/run_local.sh test
```

Or directly with dbt after `uv sync`:
```bash
cd transform && dbt deps && dbt run
dbt test
dbt run --select <model_name>
```

### Lineage

No standalone run commands. The `lineage/` package installs into `transform/` as a local dependency and is loaded automatically by dbt via `lineage/openlineage.yml`.

### Airflow (local orchestration)

```bash
cd airflow
docker-compose up airflow-init   # one-time DB migration + admin user
docker-compose up -d             # start scheduler + webserver
```

UI available at `http://localhost:8080` (admin/admin).

### Infrastructure

```bash
./scripts/infra/deploy.sh         # deploy/update CloudFormation stack
```

### Linting

Both Python components use **ruff** (line-length: 100, single quotes). Run via `uv run ruff check` or `uv run ruff format` from the respective component directory.

## Architecture

### Data Flow

1. **Airflow** (local) or **EventBridge** (production) triggers the pipeline daily at 1 PM UTC
2. **Lambda** (`ingestion/`) fetches yesterday's games from the NHL API:
   - Schedule: `https://api-web.nhle.com/v1/schedule/{date}`
   - Play-by-play per game: `https://api-web.nhle.com/v1/gamecenter/{game_id}/play-by-play`
3. **Raw storage**: JSON written to S3 (partitioned `game_data={date}/game_id={id}.json`) and/or Supabase (`raw_api_data.game_data` table)
4. **dbt** (`transform/`) reads from Supabase and produces flattened analytic tables
5. **OpenLineage** (`lineage/`) emits run events from each dbt job and Airflow task to `lineage.ol_events` in Supabase

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

### Lineage Component (`lineage/`)

A custom [OpenLineage](https://openlineage.io/) transport that writes run events directly to Supabase instead of an external Marquez server.

- `lineage/nhl_lineage/transport.py` — `PostgresTransport` / `PostgresTransportConfig`: connects via `psycopg2`, auto-creates `lineage.ol_events` in Supabase on first use, and inserts each event as a JSONB row with extracted metadata columns (`event_time`, `event_type`, `job_namespace`, `job_name`, `run_id`).
- `lineage/openlineage.yml` — shared config for both dbt (copied into the transform image at build time) and Airflow (read via `AIRFLOW__OPENLINEAGE__CONFIG_PATH`). Configures the transport and enables the `source_code_location` facet.
- Credentials pulled from env vars: `SUPABASE_DB_HOST`, `SUPABASE_DB_USER`, `SUPABASE_DB_PASSWORD` (port defaults to 6543, the Supabase pooler port).

The `lineage` package is declared as a local path dependency in `transform/pyproject.toml` so `uv sync` in `transform/` installs it automatically.

### Airflow Component (`airflow/`)

Local orchestration using Airflow 2.9.0 with LocalExecutor and a PostgreSQL metadata DB (separate from Supabase).

- `airflow/docker-compose.yml` — services: `postgres`, `airflow-init`, `scheduler`, `webserver`
- `airflow/Dockerfile` — extends `apache/airflow:2.9.0` with Docker CLI, git, and `apache-airflow-providers-openlineage`
- `dags/nhl_pipeline.py` — single DAG scheduled at `0 13 * * *`; tasks: `dbt_run >> dbt_test`
- OpenLineage events emitted for each task via the shared transport; dbt events carry a `parentRun` facet linking them to the Airflow task run

Docker socket (`/var/run/docker.sock`) is mounted so BashOperator tasks can spin up Docker containers. The project root is mounted at `/project`.

### Infrastructure (`infra/cloudformation/resources.yml`)

Single CloudFormation template provisions: S3 bucket, ECR repository, two Lambda functions, EventBridge rules, and IAM roles.

### CI/CD (`.github/workflows/`)

- `ci.yml` — on non-main push: build Docker image, tag with commit SHA + `ci`, push to ECR, deploy CloudFormation
- `cd.yml` — on main push: re-tag the CI image as `prod` and push to ECR

## Environment Setup

### Airflow (local)

Copy `airflow/.env.example` to `airflow/.env` and fill in all credentials. This file is loaded by all Airflow services and passed through to task containers.

### Production / direct script use

Create a `.env` file at the repo root with:
```
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=...
S3_BUCKET=...
SUPABASE_URL=...
SUPABASE_SECRET=...
SUPABASE_DB_HOST=...
SUPABASE_DB_USER=...
SUPABASE_DB_PASSWORD=...
```

`SUPABASE_DB_*` vars are only needed for the OpenLineage transport (direct `psycopg2` connection on port 6543).
