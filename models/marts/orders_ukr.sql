{{ config(
    materialized = 'table'
) }}

{{ create_orders_by_countries('Ukraine') }}
