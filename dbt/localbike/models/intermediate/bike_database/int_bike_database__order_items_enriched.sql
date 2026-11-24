-- Une ligne par produit vendu, enrichie avec la commande, le produit, la marque et la catégorie,
-- et les montants calculés (brut, remise, net).

with order_items as (

    select * from {{ ref('stg_bike_database__order_items') }}

),

orders as (

    select * from {{ ref('stg_bike_database__orders') }}

),

products as (

    select * from {{ ref('stg_bike_database__products') }}

),

brands as (

    select * from {{ ref('stg_bike_database__brands') }}

),

categories as (

    select * from {{ ref('stg_bike_database__categories') }}

)

select
    order_items.order_item_id,
    order_items.order_id,
    order_items.item_number,

    orders.order_date,
    orders.order_status,
    orders.customer_id,
    orders.store_id,
    orders.staff_id,

    order_items.product_id,
    products.product_name,
    products.model_year,
    brands.brand_name,
    categories.category_name,

    order_items.quantity,
    order_items.unit_price,
    order_items.discount_rate,
    order_items.quantity * order_items.unit_price                                   as gross_amount,
    round(order_items.quantity * order_items.unit_price * order_items.discount_rate, 2)       as discount_amount,
    round(order_items.quantity * order_items.unit_price * (1 - order_items.discount_rate), 2) as net_amount

from order_items
left join orders     on order_items.order_id = orders.order_id
left join products   on order_items.product_id = products.product_id
left join brands     on products.brand_id = brands.brand_id
left join categories on products.category_id = categories.category_id
