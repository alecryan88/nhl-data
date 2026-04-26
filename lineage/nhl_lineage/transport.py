from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any

import psycopg2
import psycopg2.extras
from openlineage.client.serde import Serde
from openlineage.client.transport.transport import Config, Transport

if TYPE_CHECKING:
    from openlineage.client.client import Event


@dataclass
class PostgresTransportConfig(Config):
    host: str = ''
    user: str = ''
    password: str = ''
    port: int = 6543
    database: str = 'postgres'
    table: str = 'lineage.ol_events'

    @classmethod
    def from_dict(cls, params: dict[str, Any]) -> PostgresTransportConfig:
        return cls(
            host=params.get('host', os.environ['SUPABASE_DB_HOST']),
            user=params.get('user', os.environ['SUPABASE_DB_USER']),
            password=params.get('password', os.environ['SUPABASE_DB_PASSWORD']),
            port=int(params.get('port', 6543)),
            database=params.get('database', 'postgres'),
            table=params.get('table', 'lineage.ol_events'),
        )


class PostgresTransport(Transport):
    kind = 'postgres'
    config_class = PostgresTransportConfig

    def __init__(self, config: PostgresTransportConfig) -> None:
        self.config = config
        self._conn: psycopg2.extensions.connection | None = None
        self._ensure_table()

    def _connection(self) -> psycopg2.extensions.connection:
        if self._conn is None or self._conn.closed:
            self._conn = psycopg2.connect(
                host=self.config.host,
                user=self.config.user,
                password=self.config.password,
                port=self.config.port,
                dbname=self.config.database,
            )
        return self._conn

    def _ensure_table(self) -> None:
        conn = self._connection()
        with conn.cursor() as cur:
            cur.execute('CREATE SCHEMA IF NOT EXISTS lineage')
            cur.execute("""
                CREATE TABLE IF NOT EXISTS lineage.ol_events (
                    id         BIGSERIAL PRIMARY KEY,
                    event_time TIMESTAMPTZ,
                    event_type TEXT,
                    job_namespace TEXT,
                    job_name   TEXT,
                    run_id     TEXT,
                    payload    JSONB NOT NULL,
                    created_at TIMESTAMPTZ DEFAULT NOW()
                )
            """)
        conn.commit()

    def emit(self, event: Event) -> None:
        payload = Serde.to_json(event)
        data = json.loads(payload)
        conn = self._connection()
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO lineage.ol_events
                    (event_time, event_type, job_namespace, job_name, run_id, payload)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (
                    data.get('eventTime'),
                    data.get('eventType'),
                    data.get('job', {}).get('namespace'),
                    data.get('job', {}).get('name'),
                    data.get('run', {}).get('runId'),
                    psycopg2.extras.Json(data),
                ),
            )
        conn.commit()
