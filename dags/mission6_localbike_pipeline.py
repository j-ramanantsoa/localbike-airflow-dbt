"""Mission 6 — Pipeline complet, planifié chaque jour.

test sources >> run staging >> test staging >> run intermediate >> test intermediate
            >> run mart >> test mart >> docs generate

Si une étape échoue, les suivantes ne sont pas lancées : un mart n'est jamais
reconstruit sur un staging qui n'a pas passé ses tests.
"""

from airflow import DAG
from airflow.operators.bash import BashOperator

from localbike_dbt import (
    DEFAULT_ARGS,
    INTERMEDIATE,
    MART,
    SOURCES,
    STAGING,
    START_DATE,
    dbt_docs_generate,
    dbt_run,
    dbt_test,
)

with DAG(
    dag_id="mission6_localbike_pipeline",
    description="Pipeline dbt complet : staging -> intermediate -> mart -> docs",
    start_date=START_DATE,
    # Airflow >= 2.4 : `schedule` remplace `schedule_interval` (supprimé dans Airflow 3)
    schedule="@daily",
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["localbike", "mission-6", "pipeline"],
) as dag:

    test_sources = BashOperator(task_id="test_sources", bash_command=dbt_test(SOURCES))

    run_staging = BashOperator(task_id="run_staging", bash_command=dbt_run(STAGING))
    test_staging = BashOperator(task_id="test_staging", bash_command=dbt_test(STAGING))

    run_intermediate = BashOperator(task_id="run_intermediate", bash_command=dbt_run(INTERMEDIATE))
    test_intermediate = BashOperator(task_id="test_intermediate", bash_command=dbt_test(INTERMEDIATE))

    run_mart = BashOperator(task_id="run_mart", bash_command=dbt_run(MART))
    test_mart = BashOperator(task_id="test_mart", bash_command=dbt_test(MART))

    generate_docs = BashOperator(task_id="generate_docs", bash_command=dbt_docs_generate())

    (
        test_sources
        >> run_staging
        >> test_staging
        >> run_intermediate
        >> test_intermediate
        >> run_mart
        >> test_mart
        >> generate_docs
    )
