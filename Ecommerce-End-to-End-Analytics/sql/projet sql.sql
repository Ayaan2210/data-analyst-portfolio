-- =========================================================
-- 📊 E-COMMERCE DATA ANALYSIS PROJECT (POSTGRESQL)
-- Dataset Size: 115K+ Records
-- Focus: Revenue, Customers, Delivery, Products
-- =========================================================

-- =========================================================
-- 📈 1. Monthly Revenue + Order Count
-- Purpose: Track business growth over time
-- =========================================================
SELECT
DATE_TRUNC('month', order_purchase_timestamp) AS month,
COUNT(DISTINCT order_id) AS total_orders,
SUM(payment_value) AS total_revenue,
ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM ecommerce_data_new
WHERE payment_value IS NOT NULL
GROUP BY month
ORDER BY month;

-- 💡 Insight:
-- Shows growth trends and whether revenue increase is due to more orders or higher order value

-- =========================================================
-- 👑 2. Top Customers (High Value Users)
-- Purpose: Identify most valuable customers
-- =========================================================
SELECT
customer_unique_id,
COUNT(DISTINCT order_id) AS total_orders,
SUM(payment_value) AS total_spent,
ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM ecommerce_data_new
WHERE payment_value IS NOT NULL
GROUP BY customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- 💡 Insight:
-- A small group of customers usually contributes a large portion of revenue

-- =========================================================
-- 🔁 3. Repeat vs New Customers
-- Purpose: Measure customer retention
-- =========================================================
WITH customer_orders AS (
SELECT
customer_unique_id,
COUNT(DISTINCT order_id) AS order_count
FROM ecommerce_data_new
GROUP BY customer_unique_id
)

SELECT
CASE
WHEN order_count = 1 THEN 'New'
ELSE 'Repeat'
END AS customer_type,
COUNT(*) AS total_customers,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM customer_orders
GROUP BY customer_type;

-- 💡 Insight:
-- Higher repeat customers indicate strong retention and customer satisfaction

-- =========================================================
-- 📦 4. Monthly Orders Trend
-- Purpose: Track demand trends
-- =========================================================
SELECT
DATE_TRUNC('month', order_purchase_timestamp) AS month,
COUNT(DISTINCT order_id) AS order_count
FROM ecommerce_data_new
GROUP BY month
ORDER BY month;

-- 💡 Insight:
-- Helps compare demand vs revenue growth

-- =========================================================
-- 🛍️ 5. Product Category Performance
-- Purpose: Identify best-selling categories
-- =========================================================
SELECT
product_category_name,
COUNT(DISTINCT order_id) AS total_orders,
SUM(price) AS total_revenue,
ROUND(AVG(price), 2) AS avg_price
FROM ecommerce_data_new
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY total_revenue DESC;

-- 💡 Insight:
-- Helps focus marketing on high-performing categories

-- =========================================================
-- 🚚 6. Delivery Performance
-- Purpose: Evaluate logistics efficiency
-- =========================================================
SELECT
CASE
WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
ELSE 'Late'
END AS delivery_status,
COUNT(*) AS total_orders,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM ecommerce_data_new
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

-- 💡 Insight:
-- Late deliveries can negatively impact customer satisfaction

-- =========================================================
-- ⏱️ 7. Average Delivery Time (in Days)
-- Purpose: Measure delivery efficiency
-- =========================================================
SELECT
ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp))), 2)
AS avg_delivery_days
FROM ecommerce_data_new
WHERE order_delivered_customer_date IS NOT NULL;

-- 💡 Insight:
-- Faster delivery improves customer experience and ratings

-- =========================================================
-- 💳 8. Payment Method Distribution
-- Purpose: Understand customer payment preferences
-- =========================================================
SELECT
payment_type,
COUNT(*) AS total_transactions,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM ecommerce_data_new
WHERE payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY total_transactions DESC;

-- 💡 Insight:
-- Useful for optimizing checkout experience

-- =========================================================
-- 🔥 9. Pareto Analysis (Revenue Contribution)
-- Purpose: Identify top revenue contributing customers
-- =========================================================
WITH customer_revenue AS (
SELECT
customer_unique_id,
SUM(payment_value) AS revenue
FROM ecommerce_data_new
GROUP BY customer_unique_id
),
ranked AS (
SELECT *,
SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
SUM(revenue) OVER () AS total_revenue
FROM customer_revenue
)

SELECT
customer_unique_id,
revenue,
ROUND(cumulative_revenue * 100.0 / total_revenue, 2) AS cumulative_percentage
FROM ranked
ORDER BY revenue DESC;

-- 💡 Insight:
-- Typically, top ~20% customers contribute ~80% revenue (Pareto Principle)

-- =========================================================
-- 🚀 END OF PROJECT
-- =========================================================
