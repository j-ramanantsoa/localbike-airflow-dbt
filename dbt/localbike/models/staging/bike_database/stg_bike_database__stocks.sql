with source as (

    select * from {{ source('bike_database', 'stocks') }}

)

select
    -- clé unique : un produit dans un magasin
    concat(cast(store_id as string), '-', cast(product_id as string)) as stock_id,
    cast(store_id as int64)                                           as store_id,
    cast(product_id as int64)                                         as product_id,
    cast(quantity as int64)                                           as quantity_in_stock
from source
