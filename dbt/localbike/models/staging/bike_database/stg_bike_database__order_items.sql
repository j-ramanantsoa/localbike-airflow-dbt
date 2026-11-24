with source as (

    select * from {{ source('bike_database', 'order_items') }}

)

select
    -- clé unique : une commande contient plusieurs lignes numérotées (item_id)
    concat(cast(order_id as string), '-', cast(item_id as string)) as order_item_id,
    cast(order_id as int64)                                         as order_id,
    cast(item_id as int64)                                          as item_number,
    cast(product_id as int64)                                       as product_id,
    cast(quantity as int64)                                         as quantity,
    cast(list_price as numeric)                                     as unit_price,
    cast(discount as numeric)                                       as discount_rate
from source
