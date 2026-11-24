-- Dimension : une ligne par client, avec son historique d'achat.
-- Le chiffre d'affaires ne compte que les commandes terminées (completed).

with customers as (

    select * from {{ ref('stg_bike_database__customers') }}

),

orders as (

    select * from {{ ref('int_bike_database__orders_aggregated') }}

),

customer_orders as (

    select
        customer_id,
        count(*)                                                    as order_count,
        countif(order_status = 'completed')                         as completed_order_count,
        min(order_date)                                             as first_order_date,
        max(order_date)                                             as last_order_date,
        sum(if(order_status = 'completed', net_amount, 0))          as lifetime_revenue
    from orders
    group by customer_id

)

select
    customers.customer_id,
    concat(customers.first_name, ' ', customers.last_name) as customer_name,
    customers.email,
    customers.phone,
    customers.city,
    customers.state,
    customers.zip_code,
    coalesce(customer_orders.order_count, 0)           as order_count,
    coalesce(customer_orders.completed_order_count, 0) as completed_order_count,
    customer_orders.first_order_date,
    customer_orders.last_order_date,
    coalesce(customer_orders.lifetime_revenue, 0)      as lifetime_revenue
from customers
left join customer_orders on customers.customer_id = customer_orders.customer_id
