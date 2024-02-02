
--------------------------------------------------------------------
                1. customers_by_country.sql
--------------------------------------------------------------------

SELECT
    country,
    COUNT(*) AS customers_amount
FROM {{ source('d_src', 'customers') }} 
GROUP BY country
ORDER BY country

----------------

models/marts/_marts.yml


version: 2

models:

  - name: customers_by_country
    description: |
      How many customers we have in each country
    columns:
      - name: country
        data_type: varchar
        description: |
          Country name
      - name: customers_amount
        data_type: int
        description: |
          Amount of customers in specific country


--------------------------------------------------------------------
                2. sql_producers.sql
--------------------------------------------------------------------

{{ config(
    alias="accessories_producers",
    contract={"enforced": true},
) }}

SELECT *
FROM {{ source('d_src', 'products') }}
WHERE category = 'Accessories'


----------------

  - name: sql_producers
    description: |
      Showing producers of accessorities category
    columns:
      - name: id
        data_type: int
        description: |
          id of producer
      - name: name
        data_type: varchar
        description: |
          name of product
      - name: category
        data_type: varchar
        description: |
          category of product
      - name: color
        data_type: varchar
        description: |
          product's color
      - name: producer
        data_type: varchar
        description: |
          name of producer


--------------------------------------------------------------------
                3. ukrainian_customers.sql
--------------------------------------------------------------------

{{ config(
    materialized = is_ephemeral()
) }}

SELECT * 
FROM {{ source('d_src', 'customers') }} 
WHERE country = 'Ukraine'


----------------


  - name: ukrainian_customers
    description: |
      Showing only ukrainian customers
    columns:
      - name: id
        data_type: int
        description: |
          Customer's id
      - name: name
        data_type: varchar
        description: |
          Customer's name
      - name: country
        data_type: varchar
        description: |
          Customer's country - should be Ukraine
      - name: region
        data_type: varchar
      - name: city
        data_type: varchar
      - name: street
        data_type: varchar
      - name: house
        data_type: int
      - name: apartment
        data_type: int

--------------------------------------------------------------------
                4. raw_orders.sql
--------------------------------------------------------------------

{{ config(
    materialized = 'incremental',
    incremental_strategy = 'append'
) }}

SELECT *
FROM {{ source('d_src', 'orders') }}

{% if is_incremental() %}
    WHERE id > (SELECT MAX(id) FROM {{ this }})
{% endif %}

----------------

  - name: raw_orders
    description: |
      Raw version of orders table.
      This table is processed incrementally.
    columns:
      - name: id
        data_type: int
        description: |
          id of order
      - name: product_id
        data_type: int
        description: |
          id of product
      - name: customer_id
        description: |
          id of customer
        data_type: int
      - name: amount
        data_type: int
        description: |
          amount of product were ordered
      - name: price
        data_type: decimal(10,2)
        description: |
          product price which were actual for that timestamp and customer
      - name: order_ts
        data_type: date
        description: |
          timestamp of transaction

--------------------------------------------------------------------
                5. orders_by_countries.sql
--------------------------------------------------------------------

create_orders_by_countries.sql

{%- macro create_orders_by_countries(trg_country) -%}

    SELECT o.*
    FROM {{ ref('raw_orders') }} o
    JOIN {{ source('d_src', 'customers') }} c ON o.customer_id = c.id
    WHERE c.country = '{{ trg_country }}'

{%- endmacro -%}

----------------

macros/_macros.yml

version: 2

macros:
  - name: create_orders_by_countries
    description: |
      Automate creation orders table for the specific country
    arguments:
      - name: trg_country
        type: string
        description: |
          Country for which you want to create orders table
          (required)




----------------

orders_ukr.sql

{{ config(
    materialized = 'table'
) }}

{{ create_orders_by_countries('Ukraine') }}



----------------

  - name: orders_ukr
   columns:
      - name: id
        data_type: int
      - name: product_id
        data_type: int
      - name: customer_id
        data_type: int
      - name: amount
        data_type: int
      - name: price
        data_type: decimal(10,2)
      - name: order_ts
        data_type: date


--------------------------------------------------------------------
                5. _marts.yml
--------------------------------------------------------------------


  - name: raw_orders
    description: |
      Raw version of orders table.
      This table is processed incrementally.
    columns:
      - name: id
        data_type: int
        description: |
          id of order
        tests:
          - unique
          - not_null
      - name: product_id
        data_type: int
        description: |
          id of product
        tests:
          - relationships:
              to: source('d_src', 'products')
              field: id
      - name: customer_id
        description: |
          id of customer
        data_type: int
        tests:
          - relationships:
              to: source('d_src','customers')
              field: id
      - name: amount
        data_type: int
        description: |
          amount of product were ordered
      - name: price
        data_type: decimal(10,2)
        description: |
          product price which were actual for that timestamp and customer
      - name: order_ts
        data_type: date
        description: |
          timestamp of transaction



----------------

  - name: ukrainian_customers
    description: |
      Showing only ukrainian customers
    columns:
      - name: id
        data_type: int
        description: |
          Customer's id
        tests:
          - unique
          - not_null
      - name: name
        data_type: varchar
        description: |
          Customer's name
      - name: country
        data_type: varchar
        description: |
          Customer's country - should be Ukraine
        tests:
          - accepted_values:
              values: ['Ukraine']
      - name: region
        data_type: varchar
      - name: city
        data_type: varchar
      - name: street
        data_type: varchar
      - name: house
        data_type: int
      - name: apartment
        data_type: int


----------------

test_all_orders.sql

SELECT s.*
FROM {{ source('d_src', 'orders') }} AS s
LEFT JOIN {{ ref('raw_orders') }} AS t ON s.id = t.id
WHERE t.id IS NULL


----------------

generic/test_full_trg.sql

{% test test_full_trg(model, model_src) %}

    SELECT s.*
    FROM {{ model_src }} AS s
    LEFT JOIN {{ model }} AS t ON s.id = t.id
    WHERE t.id IS NULL

{% endtest %}

----------------

tests/generic/_generic_tests.yml

version: 2

macros:
  - name: test_full_trg
    description: |
      check if target table has all the records from its source table
    arguments:
      - name: model
        type: string
        description: Checked model
      - name: model_src
        type: string
        description: Source table for specific model

----------------

  - name: raw_orders
    tests:
      - test_full_trg:
          model_src: source('d_src', 'orders')

----------------

packages.yml

packages:
  - package: calogica/dbt_expectations
    version: 0.10.1

----------------

  - name: raw_orders
    tests:
      - test_full_trg:
          model_src: source('d_src', 'orders')
      - dbt_expectations.expect_table_row_count_to_equal_other_table:
          compare_model: source('d_src', 'orders')

