/* =========================================
   BUSINESS ANALYSIS — E-COMMERCE SYSTEM
   ========================================= */

-- Total customers
SELECT COUNT(*) AS total_customers
FROM customer;

-- Orders in 2024
SELECT COUNT(*) AS total_orders_2024
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- Top 5 highest orders
SELECT order_id, customer_id, total_amount
FROM orders
ORDER BY total_amount DESC
LIMIT 5;

-- Mumbai customers
SELECT customer_id, name
FROM customer
WHERE city='Mumbai';



/* =========================================
   CUSTOMER SPENDING
   ========================================= */

SELECT 
    c.customer_id,
    c.name,
    SUM(o.total_amount) AS total_spent
FROM orders o
JOIN customer c ON o.customer_id=c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;


SELECT 
    c.customer_id,
    c.name,
    SUM(o.total_amount) AS total_spent
FROM orders o
JOIN customer c ON o.customer_id=c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC
LIMIT 3;



/* =========================================
   PRODUCT ANALYSIS
   ========================================= */

SELECT order_id,
       SUM(quantity) AS total_items
FROM order_items
GROUP BY order_id;


SELECT product_name,
       SUM(quantity) AS total_sold
FROM order_items
GROUP BY product_name
ORDER BY total_sold DESC
LIMIT 1;



/* =========================================
   WINDOW FUNCTIONS
   ========================================= */

-- Latest order per customer
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY customer_id
               ORDER BY order_date DESC
           ) rn
    FROM orders
) t
WHERE rn=1;


-- Rank customers by spending
SELECT 
    c.customer_id,
    c.name,
    SUM(o.total_amount) total_spent,
    RANK() OVER(ORDER BY SUM(o.total_amount) DESC) spending_rank
FROM orders o
JOIN customer c ON o.customer_id=c.customer_id
GROUP BY c.customer_id,c.name;


-- Previous order amount
SELECT customer_id,
       order_id,
       order_date,
       total_amount,
       LAG(total_amount) OVER(
           PARTITION BY customer_id
           ORDER BY order_date
       ) previous_amount
FROM orders;



/* =========================================
   ADVANCED ANALYSIS
   ========================================= */

-- Spending above average
SELECT customer_id,total_spent
FROM(
    SELECT customer_id,
           SUM(total_amount) total_spent
    FROM orders
    GROUP BY customer_id
) t
WHERE total_spent>(SELECT AVG(total_amount) FROM orders);


-- Monthly revenue
SELECT DATE_TRUNC('month',order_date) month,
       SUM(total_amount) revenue
FROM orders
GROUP BY month
ORDER BY month;


-- Top spender per month
WITH monthly_customer_spend AS(
    SELECT DATE_TRUNC('month',order_date) month,
           customer_id,
           SUM(total_amount) total_spent
    FROM orders
    GROUP BY month,customer_id
),
ranked AS(
    SELECT *,
           RANK() OVER(
               PARTITION BY month
               ORDER BY total_spent DESC
           ) rnk
    FROM monthly_customer_spend
)
SELECT r.month,
       c.name,
       r.total_spent
FROM ranked r
JOIN customer c ON r.customer_id=c.customer_id
WHERE rnk=1
ORDER BY r.month;



/* =========================================
   PERFORMANCE
   ========================================= */

CREATE INDEX idx_orders_date
ON orders(order_date);

EXPLAIN ANALYZE
SELECT DATE_TRUNC('month',order_date),
       SUM(total_amount)
FROM orders
GROUP BY 1;



/* =========================================
   MATERIALIZED VIEW
   ========================================= */

DROP MATERIALIZED VIEW IF EXISTS monthly_revenue;

CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT DATE_TRUNC('month',order_date) month,
       SUM(total_amount) revenue
FROM orders
GROUP BY month;

REFRESH MATERIALIZED VIEW monthly_revenue;
