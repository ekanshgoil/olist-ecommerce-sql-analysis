-- =====================================================================
-- Olist E-Commerce SQL Project | PostgreSQL | Ekansh Goil
-- Create Database and tables.
-- =====================================================================

-- Created database named olist_ecommerce

SELECT current_database();

-- WARNING: this DROP deletes all tables AND their data.
-- Run it only when setting up from scratch, never after loading the data.
DROP TABLE IF EXISTS order_payments, order_items, orders, products, customers CASCADE;

-- Create Tables

CREATE TABLE customers (
    customer_id               VARCHAR(50) PRIMARY KEY,   -- one id per ORDER
    customer_unique_id        VARCHAR(50) NOT NULL,      -- one id per REAL PERSON
    customer_zip_code_prefix  INTEGER,
    customer_city             VARCHAR(100),
    customer_state            CHAR(2)
);

CREATE TABLE products (
    product_id                  VARCHAR(50) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_lenght         NUMERIC,                 -- spelling as in source data
    product_description_lenght  NUMERIC,
    product_photos_qty          NUMERIC,
    product_weight_g            NUMERIC,
    product_length_cm           NUMERIC,
    product_height_cm           NUMERIC,
    product_width_cm            NUMERIC
);

CREATE TABLE orders (
    order_id                       VARCHAR(50) PRIMARY KEY,
    customer_id                    VARCHAR(50) NOT NULL REFERENCES customers(customer_id),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       TIMESTAMP,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP
);

CREATE TABLE order_items (
    order_id             VARCHAR(50) NOT NULL REFERENCES orders(order_id),
    order_item_id        INTEGER     NOT NULL,
    product_id           VARCHAR(50) NOT NULL REFERENCES products(product_id),
    seller_id            VARCHAR(50),
    shipping_limit_date  TIMESTAMP,
    price                NUMERIC(10,2),
    freight_value        NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id              VARCHAR(50) NOT NULL REFERENCES orders(order_id),
    payment_sequential    INTEGER     NOT NULL,
    payment_type          VARCHAR(20),
    payment_installments  INTEGER,
    payment_value         NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);


-- -----------------------------------------------------------------------
-- LOAD DATA
-- Importing/Loading data in THIS order:
-- 1) customers  2) products  3) orders  4) order_items  5) order_payments

-- After loading/importing data from the dataset we expect
-- Customer = 99,441 | Products = 32,951 | Orders = 99,441 
--	| Order_items = 112,650 | Order_payments = 103,886
-- -----------------------------------------------------------------------


SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'products',       COUNT(*) FROM products
UNION ALL SELECT 'orders',         COUNT(*) FROM orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments;



SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name IN ('customers', 'orders');

-- ---------------------------------------------------------------------
-- Basic Data Check
-- ---------------------------------------------------------------------

-- Check 1 : How many rows are in each table?

SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL SELECT 'products',	COUNT(*) FROM products
UNION ALL SELECT 'orders',		COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments;

-- Check 2 : Which order statuses exist? (Most orders should be 'delivered')

SELECT order_status, COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Check 3: Orders without a delivery date (cancelled or still in transit).
-- I only use orders with order_status = 'delivered' for sales analysis.

SELECT COUNT(*) AS orders_without_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NULL;

-- Check 4: Products with a missing category

SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;

-- Check 5: customer_id is created fresh for every order, so the same person can have
-- many customer_ids. customer_unique_id is the real customer.

SELECT 
	COUNT(DISTINCT customer_id) AS customer_ids,
	COUNT(DISTINCT customer_unique_id) AS real_customers
FROM customers;

-- =====================================================================
-- Business analysis (10 questions)
-- Revenue = total item price of DELIVERED orders (freight not included)
-- Currency: Brazilian Real (R$)
-- =====================================================================

-- Q1. How many delivered orders, how many customers and how much revenue?

SELECT 
	COUNT(DISTINCT o.order_id) AS order_delivered,
	COUNT(DISTINCT c.customer_unique_id) AS customers,
	SUM(oi.price) AS total_revenue,
	ROUND(SUM(oi.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders o 
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- Q2. How much revenue did we make each month? (2017 onwards)

SELECT
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS month,
	COUNT(DISTINCT o.order_id) AS orders,
	SUM(oi.price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
GROUP BY TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM')
ORDER BY month;

-- Q3. Which 10 product categories earn the most revenue?

SELECT
	p.product_category_name AS category,
	COUNT(*) 	AS items_sold,
	SUM(oi.price)	AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 10;

-- Q4. Which categories have sold more than 1,000 items, and what is their average price?

SELECT
	p.product_category_name AS category,
	COUNT(*) 	AS items_sold,
	AVG(oi.price)	AS avg_price
FROM order_items oi	
JOIN products p ON p.product_id = oi.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
HAVING COUNT(*) > 1000
ORDER BY items_sold DESC;

-- Q5. Which 10 states bring the most revenue?

SELECT 
	customer_state,
	COUNT(DISTINCT o.order_id) AS orders,
	SUM(oi.price) AS total_revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;

-- Q6. Which payment methods do customers use?

SELECT
	payment_type,
	COUNT(DISTINCT order_id) AS orders,
	SUM(payment_value) AS total_value,
	ROUND(AVG(payment_installments),2) AS avg_installments
FROM order_payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY total_value DESC;

-- Q7. How many days does delivery take on average, and what % of orders arrive late?

SELECT
	ROUND(AVG(DATE(o.order_delivered_customer_date) - DATE(o.order_purchase_timestamp)),1) 
				AS avg_delivery_days,
	COUNT(*) AS delivered_order,
	SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
          THEN 1 ELSE 0
		  END) AS late_orders,
	ROUND(100.0*(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
          THEN 1 ELSE 0 
		  END)) / COUNT(*),2) AS late_order_pct
FROM orders o 
WHERE order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL;

-- Q8. Which states have the slowest deliveries? (states with at least 100 orders)

SELECT 
	c.customer_state,
	COUNT(*) AS delivered_orders,
	ROUND(AVG(DATE(o.order_delivered_customer_date) - DATE(o.order_purchase_timestamp)),2) AS avg_delivery_days
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*)>= 100
ORDER BY avg_delivery_days DESC
LIMIT 10;

-- Q9. How many customers ordered more than once? (subquery)

SELECT COUNT(*) AS repeat_customers
FROM ( 
	SELECT c.customer_unique_id
	FROM orders o
	JOIN customers c ON c.customer_id = o.customer_id
	WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id
	HAVING COUNT(*)>1
	) AS repeat_buyers;

-- Q10. Which items are priced above the average item price? (subquery in WHERE)

SELECT
	p.product_category_name AS category,
	COUNT(*) AS expensive_items
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
WHERE oi.price > (SELECT AVG(price) FROM order_items)
GROUP BY p.product_category_name
ORDER BY expensive_items DESC
LIMIT 10;
