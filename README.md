# NHL Data Pipeline

An ETL pipeline that extracts NHL game data from the NHL API, stores raw JSON in Supabase and S3, transforms it with dbt, and tracks data lineage with OpenLineage. Runs on a daily schedule via AWS EventBridge in production or Apache Airflow locally.

## What It Does

1. **Ingest**: Fetches yesterday's NHL schedule and play-by-play data, uploads to Supabase and/or S3
2. **Transform**: dbt models flatten and normalize the raw JSON into analytic tables
3. **Lineage**: OpenLineage events emitted for every dbt model and Airflow task to a `lineage.ol_events` table in Supabase

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Local: Airflow DAG          Prod: EventBridge (1 PM UTC)│
└────────────────────┬────────────────────────────────────┘
                     │
              ┌──────▼──────┐
              │  ingestion/  │  AWS Lambda — fetches NHL API
              └──────┬──────┘
                     │ raw JSON
          ┌──────────┴──────────┐
          │                     │
    ┌─────▼─────┐         ┌─────▼────┐
    │  Supabase  │         │    S3    │
    │  raw table │         │ (parquet)│
    └─────┬─────┘         └──────────┘
          │
   ┌──────▼──────┐
   │  transform/  │  dbt — staging + base models
   └──────┬──────┘
          │
   ┌──────▼──────┐
   │  lineage/   │  OpenLineage → lineage.ol_events (Supabase)
   └─────────────┘
```

## Project Structure

```
├── ingestion/                 # AWS Lambda functions
│   ├── nhl_api_supabase.py    # handler → Supabase storage
│   ├── nhl_api_s3.py          # handler → S3 storage
│   ├── lib/                   # shared API client + uploaders
│   ├── Dockerfile
│   └── pyproject.toml
├── transform/                 # dbt project
│   ├── models/
│   │   ├── staging/           # stg_games: flatten raw JSONB
│   │   └── base/              # games, plays, teams, roster
│   ├── Dockerfile
│   └── pyproject.toml
├── lineage/                   # OpenLineage transport
│   ├── nhl_lineage/
│   │   └── transport.py       # PostgresTransport → Supabase
│   └── openlineage.yml        # shared config (dbt + Airflow)
├── airflow/                   # local orchestration
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── .env.example
├── dags/
│   └── nhl_pipeline.py        # dbt_run >> dbt_test, daily at 1 PM UTC
├── infra/
│   └── cloudformation/        # S3, ECR, Lambda, EventBridge, IAM
├── scripts/
│   ├── ingestion/
│   │   ├── docker/            # build/run/push for ECR deploys
│   │   └── run_local.sh       # run ingestion once, no AWS creds needed
│   ├── transform/
│   │   ├── docker/            # build/run/push for ECR deploys
│   │   └── run_local.sh       # run dbt, no AWS creds needed
│   └── shared/                # shared bash utilities
└── .env.example
```

## Prerequisites

- [uv](https://docs.astral.sh/uv/)
- Docker + Docker Compose
- Supabase project
- AWS account (for production deploys)

## Local Development

### 1. Environment

```bash
cp airflow/.env.example airflow/.env
# fill in SUPABASE_*, AWS_*, and AIRFLOW__WEBSERVER__SECRET_KEY
```

### 2. Start Airflow

```bash
cd airflow
docker-compose up airflow-init   # first-time setup
docker-compose up -d             # start scheduler + webserver
```

Open `http://localhost:8080` (admin / admin), enable the `nhl_pipeline` DAG and trigger a run.

### 3. Run components directly

```bash
# ingestion
./scripts/ingestion/run_local.sh 2024-11-01

# dbt
./scripts/transform/run_local.sh run
./scripts/transform/run_local.sh test
```

## Production Deploy

```bash
# build + push Lambda image
ENV=ci ./scripts/ingestion/docker/build.sh
ENV=ci ./scripts/ingestion/docker/push.sh

# deploy infrastructure
./scripts/infra/deploy.sh
```

CI/CD via GitHub Actions: non-main pushes build and tag the image as `ci`; merges to `main` promote it to `prod`.

## Data Models

| Table | Description |
|-------|-------------|
| `raw_api_data.game_data` | Raw play-by-play JSON from NHL API |
| `public.stg_games` | Flattened game-level staging table |
| `public.games` | One row per game |
| `public.plays` | Unnested play-by-play events |
| `public.teams` | Team reference |
| `public.roster` | Player roster per game |
| `public.skater_goals_by_season` | Aggregated goal stats |
| `lineage.ol_events` | OpenLineage run events (dbt + Airflow) |
