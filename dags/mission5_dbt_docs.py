"""Mission 5 — Documentation : génère la doc dbt.

La doc (target/index.html) est servie en continu sur http://localhost:8081
par le serveur HTTP lancé au démarrage du conteneur (voir Dockerfile).
"""

from airflow import DAG
from airflow.operators.bash import BashOperator

from localbike_dbt import DEFAULT_ARGS, START_DATE, dbt_docs_generate

with DAG(
    dag_id="mission5_dbt_docs",
    description="dbt docs generate (doc visible sur le port 8081)",
    start_date=START_DATE,
    schedule=None,
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["localbike", "mission-5", "docs"],
) as dag:

    BashOperator(task_id="generate_docs", bash_command=dbt_docs_generate())
