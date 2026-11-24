with source as (

    select * from {{ source('bike_database', 'orders') }}

)

select
    cast(order_id as int64)                             as order_id,
    cast(customer_id as int64)                          as customer_id,
    cast(store_id as int64)                             as store_id,
    cast(staff_id as int64)                             as staff_id,
    cast(order_status as int64)                         as order_status_code,
    case cast(order_status as int64)
        when 1 then 'pending'
        when 2 then 'processing'
        when 3 then 'rejected'
        when 4 then 'completed'
    end                                                 as order_status,
    cast(order_date as date)                            as order_date,
    cast(required_date as date)                         as required_date,
    -- vide tant que la commande n'est pas expédiée
    safe_cast({{ text_null('shipped_date') }} as date)  as shipped_date
from source
