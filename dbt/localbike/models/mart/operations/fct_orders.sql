-- Fait : une ligne par commande, avec ses montants et ses indicateurs de livraison.

select * from {{ ref('int_bike_database__orders_aggregated') }}
