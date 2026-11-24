with source as (

    select * from {{ source('bike_database', 'customers') }}

)

select
    cast(customer_id as int64)              as customer_id,
    trim(first_name)                        as first_name,
    trim(last_name)                         as last_name,
    {{ text_null('phone') }}                as phone,
    lower(trim(email))                      as email,
    trim(street)                            as street,
    trim(city)                              as city,
    trim(state)                             as state,
    lpad(cast(zip_code as string), 5, '0')  as zip_code
from source
