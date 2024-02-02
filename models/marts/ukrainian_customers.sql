{{ config(
    materialized = is_ephemeral()
) }}

SELECT * 
FROM {{ source('d_src', 'customers') }} 
WHERE country = 'Ukraine'
