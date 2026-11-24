-- Une commande ne peut pas être expédiée avant d'avoir été passée.
-- Le test échoue s'il renvoie au moins une ligne.

select *
from {{ ref('fct_orders') }}
where shipped_date < order_date
