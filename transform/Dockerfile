# Build stage with uv
FROM ghcr.io/astral-sh/uv:0.9.0-python3.13-bookworm-slim AS builder

WORKDIR /app

# Enable bytecode compilation for better performance
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Install dependencies first (better layer caching)
COPY transform/pyproject.toml transform/uv.lock* ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

# Runtime stage
FROM python:3.13-slim-bookworm

WORKDIR /app

# Copy the virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Add venv to PATH; add /app to PYTHONPATH so nhl_lineage is importable
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/lineage"

# Copy lineage package (no build step needed — just needs to be on PYTHONPATH)
COPY lineage/ ./lineage/

# Copy dbt project files
COPY transform/dbt_project.yml transform/packages.yml transform/profiles.yml transform/openlineage.yml ./
COPY transform/models/ ./models/
COPY transform/macros/ ./macros/
COPY transform/seeds/ ./seeds/
COPY transform/snapshots/ ./snapshots/
COPY transform/analyses/ ./analyses/
COPY transform/tests/ ./tests/

# Install dbt packages (dbt_utils, etc.)
RUN dbt deps

# Default command - can be overridden
ENTRYPOINT ["dbt-ol"]
CMD ["--help"]
