# Image unifiée Airflow + dbt
FROM apache/airflow:2.10.5-python3.12

# dbt est installé dans un environnement virtuel séparé :
# ses dépendances n'entrent pas en conflit avec celles d'Airflow.
COPY requirements-dbt.txt /tmp/requirements-dbt.txt
RUN python -m venv /home/airflow/dbt_venv \
 && /home/airflow/dbt_venv/bin/pip install --no-cache-dir -r /tmp/requirements-dbt.txt

# La commande `dbt` est disponible partout, y compris dans les tâches BashOperator
ENV PATH="${PATH}:/home/airflow/dbt_venv/bin" \
    AIRFLOW__CORE__LOAD_EXAMPLES=False

# 8080 : interface Airflow / 8081 : documentation dbt
EXPOSE 8080 8081

# Au démarrage (après suppression du PID du webserver laissé par un arrêt précédent,
# sinon Airflow croit le webserver déjà lancé et le port 8080 reste fermé) :
#  1. un serveur HTTP sert la doc dbt (target/) sur le port 8081, en arrière-plan ; 2. Airflow standalone sur 8080
CMD ["bash", "-c", "rm -f /opt/airflow/airflow-webserver.pid && mkdir -p /opt/airflow/dbt/localbike/target && (python3 -m http.server 8081 --bind 0.0.0.0 --directory /opt/airflow/dbt/localbike/target &) && exec airflow standalone"]
