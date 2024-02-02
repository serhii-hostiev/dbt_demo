{{ config(
    alias="accessories_producers",
    contract={"enforced": true},
) }}

SELECT *
FROM {{ source('d_src', 'products') }}
WHERE category = 'Accessories'
