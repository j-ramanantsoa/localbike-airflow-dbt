{#
    Dans les CSV, les valeurs manquantes sont écrites en texte : "NULL".
    Cette macro les transforme en vrai NULL, quel que soit le type détecté par BigQuery.
#}
{% macro text_null(column) -%}
    nullif(trim(cast({{ column }} as string)), 'NULL')
{%- endmacro %}
