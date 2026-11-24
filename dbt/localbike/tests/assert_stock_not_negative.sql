-- Un stock ne peut pas être négatif.
-- Le test échoue s'il renvoie au moins une ligne.

select *
from {{ ref('fct_stocks') }}
where quantity_in_stock < 0
