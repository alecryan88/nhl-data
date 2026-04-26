FROM apache/airflow:2.9.0
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends docker.io git \
    && rm -rf /var/lib/apt/lists/*
USER airflow
