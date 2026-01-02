WITH customers AS (
    SELECT
        customer_id,
        first_name,
        last_name
    FROM {{ ref('stg_jaffle_shop__customers') }}
),

orders AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        status as order_status
    FROM {{ ref('stg_jaffle_shop__orders') }}
),

payments AS (
    SELECT
        order_id,
        amount,
        payment_status
    FROM {{ ref('stg_stripe__payments') }}
    WHERE payment_status = 'success'
),

customer_orders AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS most_recent_order_date,
        COUNT(DISTINCT o.order_id) AS number_of_orders,
        COALESCE(SUM(p.amount), 0) AS lifetime_value
    FROM orders o
    LEFT JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY o.customer_id
),

final AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        co.first_order_date,
        co.most_recent_order_date,
        COALESCE(co.number_of_orders, 0) AS number_of_orders,
        COALESCE(co.lifetime_value, 0) AS lifetime_value
    FROM customers c
    LEFT JOIN customer_orders co
        ON c.customer_id = co.customer_id
)

SELECT * FROM final