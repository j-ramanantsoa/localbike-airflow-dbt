-- Une ligne par commande : montants agrégés depuis les lignes de commande,
-- et indicateurs de livraison (délai, retard).

with orders as (

    select * from {{ ref('stg_bike_database__orders') }}

),

order_items as (

    select * from {{ ref('int_bike_database__order_items_enriched') }}

),

order_totals as (

    select
        order_id,
        count(*)             as item_count,
        sum(quantity)        as total_quantity,
        sum(gross_amount)    as gross_amount,
        sum(discount_amount) as discount_amount,
        sum(net_amount)      as net_amount
    from order_items
    group by order_id

)

select
    orders.order_id,
    orders.customer_id,
    orders.store_id,
    orders.staff_id,
    orders.order_status,
    orders.order_date,
    orders.required_date,
    orders.shipped_date,

    date_diff(orders.shipped_date, orders.order_date, day) as days_to_ship,
    -- NULL tant que la commande n'est pas expédiée
    case
        when orders.shipped_date is null then null
        else orders.shipped_date > orders.required_date
    end                                                    as is_shipped_late,

    coalesce(order_totals.item_count, 0)      as item_count,
    coalesce(order_totals.total_quantity, 0)  as total_quantity,
    coalesce(order_totals.gross_amount, 0)    as gross_amount,
    coalesce(order_totals.discount_amount, 0) as discount_amount,
    coalesce(order_totals.net_amount, 0)      as net_amount

from orders
left join order_totals on orders.order_id = order_totals.order_id
