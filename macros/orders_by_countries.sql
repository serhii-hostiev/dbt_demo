{%- macro create_orders_by_countries(trg_country) -%}

    SELECT o.*
    FROM {{ ref('raw_orders') }} o
    JOIN {{ source('d_src', 'customers') }} c ON o.customer_id = c.id
    WHERE c.country = '{{ trg_country }}'

{%- endmacro -%}