"""Mission 3 — Intermediate : couche intermediate.bike_database (après validation du staging)."""

from airflow import DAG
from airflow.operators.bash import BashOperator

from localbike_dbt import DEFAULT_ARGS, INTERMEDIATE, START_DATE, dbt_run, dbt_test

with DAG(
    dag_id="mission3_intermediate",
    description="dbt run + dbt test sur la couche intermediate",
    start_date=START_DATE,
    schedule=None,
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["localbike", "mission-3", "intermediate"],
) as dag:

    run_intermediate = BashOperator(task_id="run_intermediate", bash_command=dbt_run(INTERMEDIATE))
    test_intermediate = BashOperator(task_id="test_intermediate", bash_command=dbt_test(INTERMEDIATE))

    run_intermediate >> test_intermediate
