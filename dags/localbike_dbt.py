"""Commandes dbt partagées par tous les DAG Local Bike.

Chaque tâche Airflow lance une commande dbt dans le conteneur :
    cd <projet dbt> && dbt <commande> --profiles-dir <dossier du profiles.yml>
"""

from datetime import timedelta

import pendulum

DBT_PROJECT_DIR = "/opt/airflow/dbt/localbike"
DBT_PROFILES_DIR = f"{DBT_PROJECT_DIR}/profiles"

# Sélecteurs dbt de chaque couche (chemins relatifs au projet dbt)
SOURCES = "source:bike_database"  # tables brutes chargées dans BigQuery
STAGING = "path:models/staging/bike_database"
INTERMEDIATE = "path:models/intermediate/bike_database"
MART = "path:models/mart/operations"

START_DATE = pendulum.datetime(2026, 1, 1, tz="Europe/Paris")

DEFAULT_ARGS = {
    "owner": "analytics-engineering",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}


def _dbt(args: str) -> str:
    return f"cd {DBT_PROJECT_DIR} && dbt {args} --profiles-dir {DBT_PROFILES_DIR}"


def dbt_run(select: str) -> str:
    return _dbt(f"run --select {select}")


def dbt_test(select: str) -> str:
    # --indirect-selection cautious : on ne lance que les tests dont TOUS les modèles
    # sont dans la sélection. Sans ça, tester stg customers lancerait aussi le test
    # orders.customer_id -> customers, qui échoue si orders n'est pas encore construit.
    return _dbt(f"test --select {select} --indirect-selection cautious")


def dbt_docs_generate() -> str:
    return _dbt("docs generate")
