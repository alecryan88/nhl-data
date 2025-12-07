# NHL Data Pipeline

An ETL pipeline that extracts NHL game data from the NHL API and loads it to S3. Runs as an AWS Lambda function on an hourly schedule.

## What It Does

1. Fetches the NHL schedule for the past 7 days
2. Retrieves play-by-play data for each game
3. Uploads game data to S3 (`s3://nhl-data-test/`)

## Prerequisites

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) (package manager)
- Docker
- AWS CLI configured with valid credentials
- `.env` file with AWS credentials (for local Docker runs)

## Project Structure

```
├── app/
│   └── producer.py      # Main ETL logic
├── infra/
│   └── cloudformation/  # AWS infrastructure
├── scripts/
│   ├── app/docker/      # Docker build/run scripts
│   └── shared/          # Shared bash utilities
├── Dockerfile           # Lambda container image
└── pyproject.toml       # Python dependencies
```

## Running Locally

### Option 1: Run with Python directly

```bash
# Install dependencies
uv sync

# Run the producer
uv run python -m app.producer
```

### Option 2: Run with Docker (simulates Lambda environment)

1. Create a `.env` file with your AWS credentials:

```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1
```

2. Build and run the container:

```bash
# Set environment (defaults to dev)
export ENV=dev

# Run the Docker container
./scripts/app/docker/run.sh
```

This builds the Docker image and runs it locally with hot-reloading enabled (mounts `./app` directory).

### Invoking the Lambda locally

Once the container is running, you can invoke it via curl:

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{}'
```

## Infrastructure

The pipeline is deployed to AWS using CloudFormation:

- **ECR Repository**: Stores the Docker image
- **Lambda Function**: Runs the ETL job
- **EventBridge Rule**: Triggers Lambda hourly
- **IAM Role**: Execution permissions for Lambda

Deploy infrastructure:

```bash
./scripts/infra/deploy.sh
```

## Development

### Code Style

This project uses [Ruff](https://docs.astral.sh/ruff/) for linting and formatting:

```bash
# Format code
uv run ruff format .

# Lint code
uv run ruff check .
```
