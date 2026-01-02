SELECT
    id AS order_id,
    user_id AS customer_id,
    order_date,
    status as order_status
FROM raw.jaffle_shop.orders