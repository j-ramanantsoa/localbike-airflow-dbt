-- Dimension : une ligne par produit, avec sa marque et sa catégorie.

with products as (

    select * from {{ ref('stg_bike_database__products') }}

),

brands as (

    select * from {{ ref('stg_bike_database__brands') }}

),

categories as (

    select * from {{ ref('stg_bike_database__categories') }}

)

select
    products.product_id,
    products.product_name,
    brands.brand_name,
    categories.category_name,
    products.model_year,
    products.list_price
from products
left join brands     on products.brand_id = brands.brand_id
left join categories on products.category_id = categories.category_id
