---
name: test-lambda
description: Build the ingestion Docker image, start the Lambda container locally, invoke it with the test event, stream the response, and clean up. Accepts an optional handler arg (s3 or supabase); defaults to both.
trigger: /test-lambda
args: "[s3|supabase]"
---

## Function

Test the NHL data ingestion Lambda function locally using Docker.

### Steps

1. **Determine which handler(s) to test** based on the args:
   - `s3` → only `nhl_api_s3.lambda_handler`
   - `supabase` → only `nhl_api_supabase.lambda_handler`
   - no arg (default) → test both handlers sequentially

2. **For each handler**, run the following sequence using Bash:

   a. **Start the container in the background** (it blocks, so use `run_in_background: true`):
   ```bash
   ENV=dev ./scripts/ingestion/docker/run.sh <handler>
   ```
   Capture the process so you can kill it after.

   b. **Wait ~5 seconds** for the container to be ready, then **invoke** it:
   ```bash
   curl -s -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
     -d @ingestion/test_event.json
   ```

   c. **Stop the container** after the invocation:
   ```bash
   docker stop $(docker ps -q --filter "publish=9000")
   ```

3. **Report results** — print the raw JSON response from the Lambda for each handler, and note whether the invocation succeeded or returned an error payload.

### Notes
- Always run from the repo root.
- The `.env` file at the repo root is automatically loaded by the run script via `--env-file .env`.
- A successful Lambda response looks like `{"statusCode": 200, ...}`. An error payload will contain `"errorMessage"`.
- If the container fails to start (port already in use), stop any existing container on port 9000 first:
  ```bash
  docker stop $(docker ps -q --filter "publish=9000") 2>/dev/null || true
  ```
