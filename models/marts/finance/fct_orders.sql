WITH
customers AS (
    SELECT * FROM {{ ref('stg_jaffle_shop__customers') }}
),

orders_payments AS (
    SELECT * FROM {{ ref('stg_jaffle_shop__orders') }}
    LEFT JOIN {{ ref('stg_stripe__payments') }} USING (order_id)
),

final AS (
    SELECT
        *
    FROM customers
    LEFT JOIN orders_payments USING(customer_id)
)

SELECT * FROM final