# Démarrer un projet d'Analytics Engineering

Guide d'onboarding pour une équipe Data / Produit, construit sur le projet Local Bike
(BigQuery + dbt Core + Airflow + Docker).

---

## Partie 1 — Prérequis techniques

| Prérequis | Pourquoi | Comment vérifier |
|---|---|---|
| **Docker et Docker Compose** installés | Tout le monde travaille dans le même environnement (mêmes versions d'Airflow, de dbt, de Python). Fini le « ça marche sur ma machine ». | `docker --version`, `docker compose version` |
| **Accès à un cloud data warehouse** (BigQuery) | Stocke les données et exécute les transformations SQL. | Projet GCP créé, facturation activée |
| **Compte de service + clé JSON** | dbt se connecte à BigQuery sans compte personnel. Rôles minimum : *BigQuery Data Editor* et *BigQuery Job User*. | `dbt debug` répond « All checks passed » |
| **Variables d'environnement sécurisées** (`.env`) | ID du projet, région, chemin de la clé : rien de sensible dans le code. Le `.env` et la clé sont dans le `.gitignore`. | `git status` ne les montre jamais |
| **Dataset vide dans le DW** (`bike_database`) | Accueille les données brutes. Créé dans la même région que le reste (US ou EU) : BigQuery ne joint pas des datasets de régions différentes. | Visible dans la console BigQuery |
| **Projet dbt initialisé** (`dbt init`) | Contient `dbt_project.yml` (structure) et `profiles.yml` (connexion). | `dbt debug` |
| **Orchestrateur installé** (Airflow) | Déclenche les étapes dans l'ordre et à heure fixe. | Interface sur `http://localhost:8080` |
| **Données de test** (CSV ou requêtes SQL) | Permettent de valider le pipeline de bout en bout avant de brancher les vraies sources. | 9 CSV dans `data/localbike_dataset/` |
| **Dépôt Git** | Chaque modification passe par une branche et une pull request : historique, relecture, retour arrière possible. | `git remote -v` |

---

## Partie 2 — Étapes du pipeline d'Analytics Engineering

| ✅ | Étape | Description | Dans le projet Local Bike |
|---|---|---|---|
| ☐ | 🔹 **Ingestion** | Importer les fichiers CSV ou connecter les APIs externes (Airbyte, `bq load`, interface BigQuery). Les données arrivent **brutes**, sans transformation. | 9 tables dans `bike_database` |
| ☐ | 🔹 **Staging (dbt)** | Normaliser chaque source : renommer, typer, nettoyer (ex. le texte `"NULL"` devient un vrai `NULL`). Un modèle par table source, aucune jointure. | `stg_bike_database__*.sql` (vues) |
| ☐ | 🔹 **Tests (`dbt test`)** | Contrôler la qualité dès les sources brutes puis à chaque couche : `unique`, `not_null`, `relationships`, `accepted_values`, tests métier en SQL, et tests unitaires sur les calculs. | 118 tests, dont « montant net ≥ 0 », « stock ≥ 0 » |
| ☐ | 🔹 **Intermediate** | Calculs intermédiaires réutilisables : jointures, enrichissements, agrégations. | `int_bike_database__order_items_enriched`, `int_bike_database__orders_aggregated` |
| ☐ | 🔹 **Mart** | Tables finales pour les besoins métiers, en schéma en étoile (faits + dimensions). | `mart/operations` : `fct_sales`, `fct_orders`, `fct_stocks`, `dim_*` |
| ☐ | 🔹 **Documentation** | `dbt docs generate` produit un site (descriptions, colonnes, tests, lignage). On l'expose avec un serveur HTTP. | `http://localhost:8081` |
| ☐ | 🔹 **Orchestration** | Un DAG Airflow enchaîne `run` et `test` couche par couche. Si un test échoue, la suite ne tourne pas. | `mission6_localbike_pipeline` |
| ☐ | 🔹 **Scheduling / Monitoring** | Planifier l'exécution (ex. `@daily`) et suivre l'état des tâches dans Airflow (vue Grid, logs, relances automatiques). | `schedule="@daily"`, `retries=1` |

💡 Chaque étape est versionnée dans Git, testable seule (`dbt run --select <couche>`) et déclenchable seule dans Airflow (un DAG par mission).

### Ordre d'exécution du pipeline

```
test sources → run staging → test staging → run intermediate → test intermediate → run mart → test mart → docs generate
```

---

## Partie 3 — Questions bonus

**Pourquoi utilise-t-on des layers comme staging, intermediate, mart ?**
Chaque couche a une seule responsabilité. Le **staging** nettoie les sources une seule fois : si une colonne change dans la source, on ne corrige qu'un fichier. L'**intermediate** contient la logique réutilisable (jointures, calculs de montants) pour ne pas la recopier dans chaque table finale. Le **mart** expose des tables simples, prêtes pour les analystes et les outils de BI. Résultat : un code plus lisible, des erreurs plus faciles à localiser, et des tests à chaque étage.

**Quelle est la différence entre `dbt run` et `dbt test` ?**
`dbt run` **construit** les modèles : il exécute le SQL et crée les vues ou tables dans BigQuery. `dbt test` **vérifie** les données déjà construites : chaque test est une requête qui cherche des lignes anormales (doublons, valeurs vides, clés orphelines) et échoue s'il en trouve. On enchaîne `run` puis `test` à chaque couche pour ne jamais construire la couche suivante sur des données fausses. (`dbt build` fait les deux en une commande.)

**Pourquoi documenter ses modèles avec `dbt docs` ?**
La documentation est générée à partir du code : elle reste à jour toute seule. Elle montre le rôle de chaque table et colonne, les tests en place, et le **graphe de lignage** (d'où vient chaque donnée). Un nouvel arrivant ou un analyste métier comprend le modèle sans lire le SQL, et on mesure l'impact d'une modification avant de la faire.

**Quelle est la logique de séparation des ports (Airflow sur 8080, doc sur 8081) ?**
Un port ne peut être utilisé que par un seul service à la fois. Airflow occupe le 8080, donc la documentation dbt a son propre port, 8081. Ce sont deux services indépendants : la doc reste consultable même si Airflow redémarre. Dans Docker, chaque port doit être publié explicitement (`-p 8080:8080 -p 8081:8081`), et le serveur doit écouter sur `0.0.0.0` pour être joignable depuis l'extérieur du conteneur.
