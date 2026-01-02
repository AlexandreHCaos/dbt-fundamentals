# Snowflake setup and sample data load (dbt tutorial)

This README creates the core Snowflake objects (warehouse, databases, schemas), loads three CSV datasets from a public S3 bucket into `RAW`, and validates the load with basic queries.

[Snowflake trial link](https://signup.snowflake.com/?utm_source=google&utm_medium=paidsearch&utm_campaign=na-us-en-brand-trial-exact&utm_content=go-eta-evg-ss-free-trial&utm_term=c-g-snowflake%20trial%20account-e&_bt=579123129595&_bk=snowflake%20trial%20account&_bm=e&_bn=g&_bg=136172947348)

---

## 1) Create compute and database objects

```sql
-- Compute
CREATE WAREHOUSE IF NOT EXISTS TRANSFORMING

-- Storage layers
CREATE DATABASE IF NOT EXISTS RAW;
CREATE DATABASE IF NOT EXISTS ANALYTICS;

-- Schemas for source datasets
CREATE SCHEMA IF NOT EXISTS RAW.JAFFLE_SHOP;
CREATE SCHEMA IF NOT EXISTS RAW.STRIPE;
```

Recommended context:

```sql
USE WAREHOUSE TRANSFORMING;
USE DATABASE RAW;
```

---

## 2) Load source tables from S3 (public CSVs)

To keep the `COPY` statements consistent, define a reusable file format once:

```sql
CREATE OR REPLACE FILE FORMAT RAW.PUBLIC.CSV_SKIP_HEADER_1
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL', 'null');
```

### 2.1 Customers

```sql
CREATE OR REPLACE TABLE RAW.JAFFLE_SHOP.CUSTOMERS (
  ID         INTEGER,
  FIRST_NAME VARCHAR,
  LAST_NAME  VARCHAR
);

COPY INTO RAW.JAFFLE_SHOP.CUSTOMERS (ID, FIRST_NAME, LAST_NAME)
FROM 's3://dbt-tutorial-public/jaffle_shop_customers.csv'
FILE_FORMAT = RAW.PUBLIC.CSV_SKIP_HEADER_1;
```

### 2.2 Orders

```sql
CREATE OR REPLACE TABLE RAW.JAFFLE_SHOP.ORDERS (
  ID             INTEGER,
  USER_ID        INTEGER,
  ORDER_DATE     DATE,
  STATUS         VARCHAR,
  _ETL_LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COPY INTO RAW.JAFFLE_SHOP.ORDERS (ID, USER_ID, ORDER_DATE, STATUS)
FROM 's3://dbt-tutorial-public/jaffle_shop_orders.csv'
FILE_FORMAT = RAW.PUBLIC.CSV_SKIP_HEADER_1;
```

### 2.3 Payments

```sql
CREATE OR REPLACE TABLE RAW.STRIPE.PAYMENT (
  ID            INTEGER,
  ORDERID       INTEGER,
  PAYMENTMETHOD VARCHAR,
  STATUS        VARCHAR,
  AMOUNT        INTEGER,
  CREATED       DATE,
  _BATCHED_AT   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COPY INTO RAW.STRIPE.PAYMENT (ID, ORDERID, PAYMENTMETHOD, STATUS, AMOUNT, CREATED)
FROM 's3://dbt-tutorial-public/stripe_payments.csv'
FILE_FORMAT = RAW.PUBLIC.CSV_SKIP_HEADER_1;
```

Notes:
- Uses `CREATE OR REPLACE` to make reruns idempotent.
- Uses `CREATED` (instead of mixed-case `CREATEd`) for consistent column naming.

---

## 3) Validate the load

```sql
SELECT * FROM RAW.JAFFLE_SHOP.CUSTOMERS;
SELECT * FROM RAW.JAFFLE_SHOP.ORDERS;
SELECT * FROM RAW.STRIPE.PAYMENT;
```

Optional row counts:

```sql
SELECT COUNT(*) AS CUSTOMERS_CNT FROM RAW.JAFFLE_SHOP.CUSTOMERS;
SELECT COUNT(*) AS ORDERS_CNT    FROM RAW.JAFFLE_SHOP.ORDERS;
SELECT COUNT(*) AS PAYMENTS_CNT  FROM RAW.STRIPE.PAYMENT;
```

---

## Troubleshooting tips

- If `COPY INTO` fails due to access, your Snowflake environment may require an external stage or specific network/security settings to read from S3 URLs.
- If you see unexpected NULLs, adjust `NULL_IF` in the file format and confirm CSV delimiter/enclosure settings.
