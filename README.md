# Local Bike — pipeline Airflow + dbt + BigQuery

Exercice « Créer un pipeline » de la formation Analytics Engineer (DataBird).
Local Bike migre de Snowflake vers BigQuery : ce dépôt met en place le pipeline de données avec

| Rôle | Outil |
|---|---|
| Stockage et calcul | Google BigQuery |
| Transformation, tests, documentation | dbt Core (`dbt-bigquery` 1.9) |
| Orchestration | Apache Airflow 2.10 |
| Environnement local | Docker (une seule image Airflow + dbt) |

## Architecture

```
CSV (data/localbike_dataset)
        │  Mission 0 : chargement dans BigQuery
        ▼
bike_database                    9 tables brutes
        │  source()
        ▼
<DBT_DATASET>_staging            stg_bike_database__*   vues   nettoyage, typage, "NULL" -> NULL
        │  ref()
        ▼
<DBT_DATASET>_intermediate       int_bike_database__*   vues   jointures, montants, délais
        │  ref()
        ▼
<DBT_DATASET>_mart               fct_* / dim_*          tables mart "operations"
        │
        ▼
dbt docs  ->  http://localhost:8081

Airflow (http://localhost:8080) déclenche chaque étape : test des sources brutes,
puis dbt run et dbt test, couche par couche.
```

### Modèles

| Couche | Modèle | Grain |
|---|---|---|
| staging | `stg_bike_database__{brands, categories, customers, orders, order_items, products, staffs, stocks, stores}` | une ligne par ligne source |
| intermediate | `int_bike_database__order_items_enriched` | un produit vendu + commande, produit, marque, catégorie, montants |
| intermediate | `int_bike_database__orders_aggregated` | une commande + totaux + délai d'expédition, retard |
| mart | `fct_sales` | un produit vendu (partitionnée par mois, clusterisée par magasin) |
| mart | `fct_orders` | une commande |
| mart | `fct_stocks` | un produit dans un magasin, avec valeur du stock |
| mart | `dim_customers`, `dim_products`, `dim_stores`, `dim_staffs` | une ligne par entité |

Statuts de commande : 1 = `pending`, 2 = `processing`, 3 = `rejected`, 4 = `completed`.
Le chiffre d'affaires client (`dim_customers.lifetime_revenue`) ne compte que les commandes `completed`.

## Arborescence

```
.
├── Dockerfile               image Airflow + dbt (dbt dans un venv séparé)
├── docker-compose.yml       équivalent du docker run, en une commande
├── requirements-dbt.txt
├── .env.example             variables à copier dans .env (non versionné)
├── credentials/             clé JSON du compte de service (non versionnée)
├── data/localbike_dataset/  les 9 CSV sources
├── dags/
│   ├── localbike_dbt.py                     commandes dbt partagées
│   ├── mission1_staging_brands_customers.py
│   ├── mission2_staging.py
│   ├── mission3_intermediate.py
│   ├── mission4_mart_operations.py
│   ├── mission5_dbt_docs.py
│   └── mission6_localbike_pipeline.py       pipeline complet @daily
├── dbt/localbike/
│   ├── dbt_project.yml
│   ├── profiles/profiles.yml   connexion BigQuery (lit les variables d'environnement)
│   ├── macros/text_null.sql
│   ├── models/staging/bike_database/
│   ├── models/intermediate/bike_database/
│   ├── models/mart/operations/
│   └── tests/                  tests métier
└── projet_ae.md             livrable Mission BONUS
```

## Mise en route

### 1. Google Cloud

1. **Compte de service** : IAM → Comptes de service → créer, avec les rôles
   *BigQuery Data Editor* et *BigQuery Job User*. Créer une clé JSON et l'enregistrer sous
   `credentials/gcp-key.json`.
2. **Variables** : copier `.env.example` en `.env` et renseigner `GCP_PROJECT_ID` et `GCP_LOCATION`.

### 2. Mission 0 — charger les données dans BigQuery

1. Créer le dataset `bike_database`, dans la **même région** que `GCP_LOCATION`.
2. Pour chaque fichier de `data/localbike_dataset/` : *Créer une table* → Source *Importer* →
   format CSV → nom de table = nom du fichier sans `.csv` → schéma *Détection automatique*.
   Mission 0 : `brands` et `customers` suffisent ; Mission 2 : les 9 tables.

Avec le SDK Google Cloud installé, équivalent en ligne de commande :

```bash
for t in brands categories customers orders order_items products staffs stocks stores; do
  bq load --autodetect --skip_leading_rows=1 --source_format=CSV \
    bike_database.$t data/localbike_dataset/$t.csv
done
```

Les valeurs manquantes sont écrites `NULL` en texte dans les CSV : le staging les convertit
(macro `text_null`), quel que soit le type détecté par BigQuery.

### 3. Lancer Airflow + dbt dans Docker

Docker Desktop doit être démarré.

```powershell
docker build -t localbike-airflow-dbt .

docker run -d --name localbike-airflow `
  -p 8080:8080 -p 8081:8081 `
  --env-file .env `
  -v "${PWD}/dags:/opt/airflow/dags" `
  -v "${PWD}/dbt:/opt/airflow/dbt" `
  -v "${PWD}/credentials:/opt/airflow/credentials:ro" `
  localbike-airflow-dbt
```

Ou, en une commande : `docker compose up -d --build`.

- Airflow : <http://localhost:8080>, utilisateur `admin`. Mot de passe :
  `docker exec localbike-airflow cat /opt/airflow/standalone_admin_password.txt`
- Documentation dbt : <http://localhost:8081> (après la Mission 5 ou 6)

Vérifier la connexion à BigQuery :

```bash
docker exec -it localbike-airflow bash -c "cd /opt/airflow/dbt/localbike && dbt debug --profiles-dir profiles"
```

### 4. Les missions dans Airflow

| Mission | DAG | Ce qu'il fait |
|---|---|---|
| 1 | `mission1_staging_brands_customers` | test source + run + test de `brands` et `customers`, chacun séparément |
| 2 | `mission2_staging` | test des 9 sources, puis run + test de toute la couche staging |
| 3 | `mission3_intermediate` | run + test de la couche intermediate |
| 4 | `mission4_mart_operations` | run + test du mart `operations` |
| 5 | `mission5_dbt_docs` | `dbt docs generate` → doc servie sur le port 8081 |
| 6 | `mission6_localbike_pipeline` | tout le pipeline dans l'ordre, chaque jour (`@daily`) |

Commande lancée par chaque tâche (voir `dags/localbike_dbt.py`) :

```bash
cd /opt/airflow/dbt/localbike && dbt run --select path:models/staging/bike_database --profiles-dir /opt/airflow/dbt/localbike/profiles
```

### Mission 5 — pourquoi la doc est sur un autre port qu'Airflow ?

Un port ne peut être écouté que par un seul programme à la fois. Le webserver Airflow occupe
déjà le 8080 ; le serveur de documentation (`python3 -m http.server 8081 --bind 0.0.0.0`) doit
donc écouter sur un autre port. `--bind 0.0.0.0` le rend joignable depuis l'extérieur du
conteneur, et `-p 8081:8081` relie le port 8081 de la machine à celui du conteneur.
Ce sont deux services indépendants : on peut consulter la doc même si Airflow redémarre.

Le serveur de doc est lancé au démarrage du conteneur (dernière ligne du `Dockerfile`) et
sert le dossier `target/`, que `dbt docs generate` met à jour.

## Tests

118 tests au total, à chaque étape du pipeline :

| Étape | Nb | Type | Exemple |
|---|---|---|---|
| Sources brutes | 21 | `unique`, `not_null` | clés des 9 tables de `bike_database` : le chargement des CSV est-il complet ? |
| Staging / intermediate / mart | 92 | `unique`, `not_null` | chaque clé primaire (`order_id`, `sale_id`, `stock_id`…) |
| | | `relationships` | `fct_sales.store_id` → `dim_stores`, `stg orders.customer_id` → `stg customers` |
| | | `accepted_values` | `order_status` ∈ {pending, processing, rejected, completed} |
| Tests métier (`tests/`) | 3 | SQL | montant net ≥ 0, stock ≥ 0, expédition après la commande |
| Tests unitaires | 2 | `unit_tests` | calcul brut / remise / net ; totaux et retard par commande, sur des lignes inventées |

Les **tests de données** vérifient les vraies données. Les **tests unitaires** vérifient la
logique SQL sur des cas choisis exprès (commande non expédiée, commande sans ligne…).

Lancer les tests à la main :

```bash
cd /opt/airflow/dbt/localbike
dbt test --select source:bike_database --profiles-dir profiles          # sources brutes
dbt test --select path:models/staging --profiles-dir profiles           # une couche
dbt test --select test_type:unit --profiles-dir profiles                # tests unitaires seuls
dbt build --profiles-dir profiles                                       # run + test de tout, dans l'ordre
```

Les tests sont lancés avec `--indirect-selection cautious` : quand on teste une partie des
modèles, seuls les tests dont **tous** les modèles sont sélectionnés tournent.

## Sécurité

La clé JSON (`credentials/`) et le `.env` sont dans le `.gitignore` et ne doivent jamais être poussés.
`profiles.yml` ne contient aucun secret : il lit les variables d'environnement.
