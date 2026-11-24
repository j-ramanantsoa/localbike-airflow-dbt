-- Fait : une ligne par produit et par magasin, avec la valeur du stock au prix catalogue.

with stocks as (

    select * from {{ ref('stg_bike_database__stocks') }}

),

products as (

    select * from {{ ref('stg_bike_database__products') }}

)

select
    stocks.stock_id,
    stocks.store_id,
    stocks.product_id,
    stocks.quantity_in_stock,
    stocks.quantity_in_stock = 0                        as is_out_of_stock,
    stocks.quantity_in_stock * products.list_price      as stock_value
from stocks
left join products on stocks.product_id = products.product_id
