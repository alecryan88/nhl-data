# NHL Data Pipeline

An ETL pipeline that extracts NHL game data from the NHL API and loads it to Supabase and S3. Runs as AWS Lambda functions on a daily schedule. Includes dbt transformations for data modeling.

## What It Does

1. **Ingestion**: Fetches NHL schedule and play-by-play data, uploads to Supabase/S3
2. **Transform**: dbt models for cleaning and transforming the raw data

## Architecture

This project is split into two independent components, each with its own Docker image and Python environment:

- **`ingestion/`** - AWS Lambda functions for data extraction
- **`transform/`** - dbt project for data transformation

## Prerequisites

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) (package manager)
- Docker
- AWS CLI configured with valid credentials
- Supabase project with credentials (for Supabase storage)
- `.env` file with credentials (for local runs)

## Project Structure

```
├── ingestion/                 # Lambda ingestion functions
│   ├── pyproject.toml         # Ingestion Python dependencies
│   ├── Dockerfile             # Lambda container image
│   ├── nhl_api_supabase.py    # Lambda handler for Supabase storage
│   ├── nhl_api_s3.py          # Lambda handler for S3 storage
│   ├── test_event.json        # Sample EventBridge event for testing
│   └── lib/
│       ├── nhl_api.py         # NHL API client
│       ├── supbase_uploader.py   # Supabase upload logic
│       └── s3_uploader.py     # S3 upload logic
├── transform/                 # dbt transformation layer
│   ├── pyproject.toml         # dbt Python dependencies
│   ├── Dockerfile             # dbt container image
│   ├── dbt_project.yml        # dbt project config
│   ├── models/                # dbt models
│   └── ...
├── infra/
│   └── cloudformation/        # AWS infrastructure
├── scripts/
│   ├── ingestion/docker/      # Ingestion Docker build/run scripts
│   ├── transform/docker/      # Transform Docker build/run scripts
│   └── shared/                # Shared bash utilities
└── pyproject.toml             # (legacy - can be removed)
```

## Setup

Each component has its own Python environment. Navigate to the directory and run:

```bash
# For ingestion development
cd ingestion
uv sync

# For transform (dbt) development
cd transform
uv sync
```

## Running Ingestion

### Run with Docker (simulates Lambda environment)

1. Create a `.env` file in the project root with your credentials:

```bash
# AWS credentials (for S3 storage)
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1

# Supabase credentials (for Supabase storage)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SECRET=your_service_role_key
```

2. Build and run the container:

```bash
# Set environment (defaults to dev)
export ENV=dev

# Run the Docker container with a handler
./scripts/ingestion/docker/run.sh nhl_api_s3.lambda_handler
```

### Invoking the Lambda locally

Once the container is running, you can invoke it via curl:

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d @ingestion/test_event.json
```

## Running dbt Transforms

### Run with Docker

```bash
# Set environment
export ENV=dev

# Run dbt commands via Docker
./scripts/transform/docker/run.sh run          # Run all models
./scripts/transform/docker/run.sh test         # Run tests
./scripts/transform/docker/run.sh build        # Run + test
./scripts/transform/docker/run.sh compile      # Compile SQL
```

### Run locally (without Docker)

```bash
cd transform
uv sync
source .venv/bin/activate  # or use: uv run dbt ...

dbt deps      # Install dbt packages
dbt run       # Run models
dbt test      # Run tests
```

## Infrastructure

The pipeline is deployed to AWS using CloudFormation:

- **Supabase**: External hosted database for game data (not deployed by this script—credentials stored in SSM Parameter Store)
- **S3 Bucket**: Alternative storage option (`${ProjectName}-data`)
- **ECR Repository**: Stores the Docker images
- **Lambda Functions**: Two functions—one for Supabase, one for S3
- **EventBridge Rule**: Triggers Lambdas daily
- **IAM Role**: Execution permissions for Lambda

Deploy infrastructure:

```bash
./scripts/infra/deploy.sh
```
