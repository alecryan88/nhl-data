from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.openlineage.plugins.macros import lineage_run_id

PROJECT_ROOT = '/project'

with DAG(
    dag_id='nhl_pipeline',
    schedule='0 13 * * *',
    start_date=datetime(2024, 10, 1),
    catchup=False,
    tags=['nhl'],
    user_defined_macros={'lineage_run_id': lineage_run_id},
) as dag:
    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command=f'{PROJECT_ROOT}/scripts/transform/run_local.sh run',
        env={'OPENLINEAGE_PARENT_ID': 'nhl/nhl_pipeline.dbt_run/{{ lineage_run_id(task_instance) }}'},
        append_env=True,
    )

    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command=f'{PROJECT_ROOT}/scripts/transform/run_local.sh test',
        env={'OPENLINEAGE_PARENT_ID': 'nhl/nhl_pipeline.dbt_test/{{ lineage_run_id(task_instance) }}'},
        append_env=True,
    )

    dbt_run >> dbt_test
