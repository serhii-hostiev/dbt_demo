
SELECT s.*
FROM {{ source('d_src', 'orders') }} AS s
LEFT JOIN {{ ref('raw_orders') }} AS t ON s.id = t.id
WHERE t.id IS NULL
