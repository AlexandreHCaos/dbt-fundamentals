SELECT
    id,
    orderid as order_id,
    status as payment_status,
    amount / 100 as amount,
FROM {{ source('stripe', 'payment') }}