from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

PROJECT_ROOT = '/project'

with DAG(
    dag_id='nhl_pipeline',
    schedule='0 13 * * *',
    start_date=datetime(2024, 10, 1),
    catchup=False,
    tags=['nhl'],
) as dag:
    ingest = BashOperator(
        task_id='ingest_supabase',
        bash_command=f'{PROJECT_ROOT}/scripts/ingestion/run_local.sh {{{{ ds }}}}',
    )

    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command=f'{PROJECT_ROOT}/scripts/transform/run_local.sh run',
    )

    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command=f'{PROJECT_ROOT}/scripts/transform/run_local.sh test',
    )

    ingest >> dbt_run >> dbt_test
