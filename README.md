# NHL Data Pipeline

An ETL pipeline that extracts NHL game data from the NHL API and loads it to Supabase and S3. Runs as AWS Lambda functions on a daily schedule.

## What It Does

1. Fetches the NHL schedule for the previous day
2. Retrieves play-by-play data for each game
3. Uploads game data to Supabase and S3

## Architecture

## Prerequisites

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) (package manager)
- Docker
- AWS CLI configured with valid credentials
- Supabase project with credentials (for Supabase storage)
- `.env` file with credentials (for local runs)

## Project Structure

```
├── ingestion/
│   ├── nhl_api_supabase.py   # Lambda handler for Supabase storage
│   ├── nhl_api_s3.py         # Lambda handler for S3 storage
│   ├── test_event.json       # Sample EventBridge event for testing
│   └── lib/
│       ├── nhl_api.py        # NHL API client
│       ├── supbase_uploader.py  # Supabase upload logic
│       └── s3_uploader.py    # S3 upload logic
├── transform/                # dbt project for data transformation
├── infra/
│   └── cloudformation/       # AWS infrastructure
├── scripts/
│   ├── ingestion/docker/     # Docker build/run scripts
│   └── shared/               # Shared bash utilities
├── Dockerfile                # Lambda container image
└── pyproject.toml            # Python dependencies
```

## Running Locally

### Run with Docker (simulates Lambda environment)

1. Create a `.env` file with your credentials:

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

# Run the Docker container
./scripts/ingestion/docker/run.sh
```

This builds the Docker image and runs it locally with hot-reloading enabled (mounts `./ingestion` directory).

### Invoking the Lambda locally

Once the container is running, you can invoke it via curl:

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d @ingestion/test_event.json
```

The `test_event.json` is a sample EventBridge Scheduler payload. The Lambda uses the `time` field to determine which date to fetch games for (it processes games from the day before the event time).

## Infrastructure

The pipeline is deployed to AWS using CloudFormation:

- **Supabase**: External hosted database for game data (not deployed by this script—credentials stored in SSM Parameter Store)
- **S3 Bucket**: Alternative storage option (`${ProjectName}-data`)
- **ECR Repository**: Stores the Docker image
- **Lambda Functions**: Two functions—one for Supabase, one for S3
- **EventBridge Rule**: Triggers Lambdas daily
- **IAM Role**: Execution permissions for Lambda

Deploy infrastructure:

```bash
./scripts/infra/deploy.sh
```
