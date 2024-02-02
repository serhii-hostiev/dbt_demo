{{ config(
    materialized = 'incremental',
    incremental_strategy = 'append'
) }}

SELECT *
FROM {{ source('d_src', 'orders') }}

{% if is_incremental() %}
    WHERE id > (SELECT MAX(id) FROM {{ this }})
{% endif %}
