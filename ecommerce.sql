CREATE DATABASE ecommerce_db;
SHOW DATABASES;
USE ecommerce_db;
SHOW TABLES;

#Which order status has the highest number of orders?
SELECT 
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC
limit 1;

#How many different cities are there?
SELECT COUNT(DISTINCT city) AS different_cities
FROM customers;

#How many customers are in each segment?
SELECT 
    customer_segment,
    COUNT(*) AS customer_count
FROM customers
GROUP BY customer_segment
ORDER BY customer_count DESC;

#Which payment method is most commonly used?
SELECT
    payment_method,
    COUNT(*) AS payment_count
FROM payments
GROUP BY payment_method
ORDER BY payment_count DESC
LIMIT 1;

#which category contains the highest number of products?
SELECT
    category,
    COUNT(*) AS product_count
FROM products
GROUP BY category
ORDER BY product_count DESC
LIMIT 1;

#What is the average quantity per order item?
SELECT
    AVG(quantity) AS average_quantity
FROM order_items;

#Which product has the highest total quantity sold?
SELECT
    p.product_name,
    SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 1;

#Which category has the highest total quantity sold?
SELECT
    p.category,
    SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_quantity DESC
LIMIT 1;

#What is the total revenue?
SELECT
    SUM(quantity * selling_price) AS total_revenue
FROM order_items;

#What is the average order value (AOV)?
CREATE VIEW aov_analysis AS
SELECT
    AVG(order_revenue) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(quantity * selling_price) AS order_revenue
    FROM order_items
    GROUP BY order_id
) AS order_totals;

#Which customer generated the highest revenue?
CREATE VIEW customer_revenue_analysis AS
SELECT
    c.customer_name,
    SUM(oi.quantity * oi.selling_price) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_name
ORDER BY total_revenue DESC;

#Which customer segment generated the highest revenue?
CREATE VIEW segment_revenue_analysis AS
SELECT
    c.customer_segment,
    SUM(oi.quantity * oi.selling_price) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;

#Which city generated the highest revenue?
CREATE VIEW city_revenue_analysis AS
SELECT
    c.city,
    SUM(oi.quantity * oi.selling_price) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.city
ORDER BY total_revenue DESC;

#Which product generated the highest revenue?
CREATE VIEW product_revenue_analysis AS
SELECT
    p.product_name,
    SUM(oi.quantity * oi.selling_price) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

#Which category generated the highest revenue?
CREATE VIEW category_revenue_analysis AS
SELECT
    p.category,
    SUM(oi.quantity * oi.selling_price) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

#Which month had the highest revenue?
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    SUM(oi.quantity * oi.selling_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY total_revenue DESC;

#Which payment method generated the highest revenue?
CREATE VIEW payment_revenue_analysis AS
SELECT
    o.payment_method,
    SUM(oi.quantity * oi.selling_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.payment_method
ORDER BY total_revenue DESC;

#Which products generated the highest profit?
CREATE VIEW product_profit_analysis AS
SELECT
    p.product_name,
    SUM(
        oi.quantity * (oi.selling_price - p.cost_price)
    ) AS total_profit
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC;

#Which category generated the highest profit?
CREATE VIEW category_profit_analysis AS
SELECT
    p.category,
    SUM(
        oi.quantity * (oi.selling_price - p.cost_price)
    ) AS total_profit
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_profit DESC;

#What is the ranking of products by revenue within each category?
CREATE VIEW product_category_ranking AS
SELECT
    p.category,
    p.product_name,
    SUM(oi.quantity * oi.selling_price) AS total_revenue,
    RANK() OVER (
        PARTITION BY p.category
        ORDER BY SUM(oi.quantity * oi.selling_price) DESC
    ) AS revenue_rank
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category, p.product_name
ORDER BY p.category, revenue_rank;

#How did this month's revenue change compared with the previous month?
CREATE VIEW monthly_revenue_analysis AS
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.selling_price) AS monthly_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY month
    ) AS cumulative_revenue
FROM monthly_sales;

#Find the highest-revenue order for each customer.
CREATE VIEW highest_order_per_customer AS
WITH order_revenue AS (
    SELECT
        o.customer_id,
        o.order_id,
        SUM(oi.quantity * oi.selling_price) AS order_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_id
),
ranked_orders AS (
    SELECT
        customer_id,
        order_id,
        order_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_revenue DESC
        ) AS order_rank
    FROM order_revenue
)
SELECT
    customer_id,
    order_id,
    order_revenue
FROM ranked_orders
WHERE order_rank = 1;

#What is the cumulative revenue over time?
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.selling_price) AS monthly_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)

SELECT
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY month
    ) AS cumulative_revenue
FROM monthly_sales
ORDER BY month;
USE ecommerce_db;

SHOW FULL TABLES
WHERE TABLE_TYPE = 'VIEW';