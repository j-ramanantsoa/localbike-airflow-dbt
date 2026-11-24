-- Dimension : une ligne par membre du personnel, avec le nom de son manager.

with staffs as (

    select * from {{ ref('stg_bike_database__staffs') }}

)

select
    staffs.staff_id,
    concat(staffs.first_name, ' ', staffs.last_name)    as staff_name,
    staffs.email,
    staffs.is_active,
    staffs.store_id,
    staffs.manager_id,
    concat(managers.first_name, ' ', managers.last_name) as manager_name
from staffs
left join staffs as managers on staffs.manager_id = managers.staff_id
