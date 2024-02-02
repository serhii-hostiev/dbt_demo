SELECT
    country,
    COUNT(*) AS customers_amount
FROM {{ source('d_src', 'customers') }} 
GROUP BY country
ORDER BY country
