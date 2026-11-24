-- Une vente ne peut pas avoir un montant net négatif (remise > 100 %).
-- Le test échoue s'il renvoie au moins une ligne.

select *
from {{ ref('fct_sales') }}
where net_amount < 0
