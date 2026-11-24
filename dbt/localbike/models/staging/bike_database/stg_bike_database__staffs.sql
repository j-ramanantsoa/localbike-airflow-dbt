with source as (

    select * from {{ source('bike_database', 'staffs') }}

)

select
    cast(staff_id as int64)                             as staff_id,
    trim(first_name)                                    as first_name,
    trim(last_name)                                     as last_name,
    lower(trim(email))                                  as email,
    trim(phone)                                         as phone,
    lower(cast(active as string)) in ('1', 'true')      as is_active,
    cast(store_id as int64)                             as store_id,
    -- vide pour la personne en haut de la hiérarchie (pas de manager)
    safe_cast({{ text_null('manager_id') }} as int64)   as manager_id
from source
