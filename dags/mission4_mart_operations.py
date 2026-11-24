"""Mission 4 — Mart : couche mart.operations dans un DAG dédié."""

from airflow import DAG
from airflow.operators.bash import BashOperator

from localbike_dbt import DEFAULT_ARGS, MART, START_DATE, dbt_run, dbt_test

with DAG(
    dag_id="mission4_mart_operations",
    description="dbt run + dbt test sur le mart operations",
    start_date=START_DATE,
    schedule=None,
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["localbike", "mission-4", "mart"],
) as dag:

    run_mart = BashOperator(task_id="run_mart", bash_command=dbt_run(MART))
    test_mart = BashOperator(task_id="test_mart", bash_command=dbt_test(MART))

    run_mart >> test_mart
