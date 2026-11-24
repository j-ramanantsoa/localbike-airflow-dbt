"""Mission 1 — Staging table par table : brands et customers, run puis test séparément.

Pour chaque table : test de la source brute >> dbt run >> dbt test.
"""

from airflow import DAG
from airflow.operators.bash import BashOperator

from localbike_dbt import DEFAULT_ARGS, START_DATE, dbt_run, dbt_test

with DAG(
    dag_id="mission1_staging_brands_customers",
    description="dbt run + dbt test sur stg brands et stg customers, table par table",
    start_date=START_DATE,
    schedule=None,  # lancement manuel
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["localbike", "mission-1", "staging"],
) as dag:

    for table in ["brands", "customers"]:
        model = f"stg_bike_database__{table}"

        test_source = BashOperator(
            task_id=f"test_source_{table}",
            bash_command=dbt_test(f"source:bike_database.{table}"),
        )
        run = BashOperator(task_id=f"run_stg_{table}", bash_command=dbt_run(model))
        test = BashOperator(task_id=f"test_stg_{table}", bash_command=dbt_test(model))

        test_source >> run >> test
