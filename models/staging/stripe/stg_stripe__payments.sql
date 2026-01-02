SELECT
    id,
    orderid as order_id,
    status as payment_status,
    amount,
FROM raw.stripe.payment