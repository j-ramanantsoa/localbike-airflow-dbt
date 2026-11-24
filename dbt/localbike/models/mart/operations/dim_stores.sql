-- Dimension : une ligne par magasin, avec son effectif.

with stores as (

    select * from {{ ref('stg_bike_database__stores') }}

),

staff_counts as (

    select
        store_id,
        count(*) as staff_count
    from {{ ref('stg_bike_database__staffs') }}
    group by store_id

)

select
    stores.store_id,
    stores.store_name,
    stores.city,
    stores.state,
    stores.zip_code,
    stores.email,
    stores.phone,
    coalesce(staff_counts.staff_count, 0) as staff_count
from stores
left join staff_counts on stores.store_id = staff_counts.store_id
