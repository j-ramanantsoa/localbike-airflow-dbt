-- Fait : une ligne par produit vendu.
-- Partitionnée par mois de commande et clusterisée par magasin.

{{
    config(
        partition_by={'field': 'order_date', 'data_type': 'date', 'granularity': 'month'},
        cluster_by=['store_id']
    )
}}

select
    order_item_id   as sale_id,
    order_id,
    order_date,
    order_status,
    customer_id,
    store_id,
    staff_id,
    product_id,
    quantity,
    unit_price,
    discount_rate,
    gross_amount,
    discount_amount,
    net_amount
from {{ ref('int_bike_database__order_items_enriched') }}
