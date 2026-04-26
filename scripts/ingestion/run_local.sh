#!/bin/bash
set -euo pipefail

DATE="${1:?Usage: $0 <date (YYYY-MM-DD)>}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Building ingestion image..."
docker build -t nhl-ingestion:local -f "$PROJECT_ROOT/ingestion/Dockerfile" "$PROJECT_ROOT/ingestion"

echo "Running ingestion for date: $DATE"
docker run --rm \
    --env-file "$PROJECT_ROOT/ingestion/.env" \
    nhl-ingestion:local \
    python -c "
import sys
from nhl_api_supabase import lambda_handler
result = lambda_handler({'time': '${DATE}T13:00:00Z', 'detail': {}}, None)
print(result)
sys.exit(0 if result.get('statusCode') == 200 else 1)
"
