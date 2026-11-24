"""Mission 2 — Staging complet : toutes les tables de staging.bike_database d'un coup.

test des sources brutes >> dbt run staging >> dbt test staging
"""

from airflow import DAG
from airflow.operators.bash import BashOperator

from localbike_dbt import DEFAULT_ARGS, SOURCES, STAGING, START_DATE, dbt_run, dbt_test

with DAG(
    dag_id="mission2_staging",
    description="Test des sources, puis dbt run + dbt test sur toute la couche staging",
    start_date=START_DATE,
    schedule=None,
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["localbike", "mission-2", "staging"],
) as dag:

    test_sources = BashOperator(task_id="test_sources", bash_command=dbt_test(SOURCES))
    run_staging = BashOperator(task_id="run_staging", bash_command=dbt_run(STAGING))
    test_staging = BashOperator(task_id="test_staging", bash_command=dbt_test(STAGING))

    test_sources >> run_staging >> test_staging
