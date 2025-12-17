# Build stage with uv
FROM ghcr.io/astral-sh/uv:0.9.0-python3.13-bookworm-slim AS builder

WORKDIR /app

# Enable bytecode compilation for better performance
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Install dependencies first (better layer caching)
COPY pyproject.toml uv.lock* ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

# Runtime stage
FROM python:3.13-slim-bookworm

WORKDIR /app

# Copy the virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Add venv to PATH
ENV PATH="/app/.venv/bin:$PATH"

# Copy dbt project files
COPY dbt_project.yml packages.yml ./
COPY models/ ./models/
COPY macros/ ./macros/
COPY seeds/ ./seeds/
COPY snapshots/ ./snapshots/
COPY analyses/ ./analyses/
COPY tests/ ./tests/

# Install dbt packages (dbt_utils, etc.)
RUN dbt deps

# Default command - can be overridden
ENTRYPOINT ["dbt"]
CMD ["--help"]

