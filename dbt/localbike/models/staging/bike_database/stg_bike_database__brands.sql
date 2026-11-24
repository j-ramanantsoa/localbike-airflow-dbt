with source as (

    select * from {{ source('bike_database', 'brands') }}

)

select
    cast(brand_id as int64) as brand_id,
    trim(brand_name)        as brand_name
from source
