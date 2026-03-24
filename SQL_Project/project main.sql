/* =========================================================
   📊 GLOBAL SUPERSTORE SQL PROJECT
   ========================================================= */


/* =========================================================
   🔹 1. OVERALL BUSINESS PERFORMANCE
   ========================================================= */

SELECT 
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS profit_margin
FROM superstore;


/* =========================================================
   🔹 2. CATEGORY PERFORMANCE
   ========================================================= */

SELECT 
    category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM superstore
GROUP BY category
ORDER BY total_sales DESC;


/* =========================================================
   🔹 3. MONTHLY SALES TREND
   ========================================================= */

WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY 1
)
SELECT 
    month,
    total_sales
FROM monthly_sales
ORDER BY month;


/* =========================================================
   🔹 4. MONTH-OVER-MONTH GROWTH %
   ========================================================= */

WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY 1
),
sales_growth AS (
    SELECT 
        month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY month) AS prev_sales
    FROM monthly_sales
)
SELECT 
    month,
    total_sales,
    ROUND((total_sales - prev_sales) * 100.0 / NULLIF(prev_sales, 0), 2) AS growth_pct
FROM sales_growth
WHERE prev_sales IS NOT NULL
ORDER BY month;


/* =========================================================
   🔹 5. BEST PERFORMING MONTH
   ========================================================= */

WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY 1
)
SELECT 
    month,
    total_sales
FROM monthly_sales
ORDER BY total_sales DESC
LIMIT 1;


/* =========================================================
   🔹 6. CUSTOMER ANALYSIS
   ========================================================= */

-- Total Sales per Customer
SELECT 
    customer_id,
    customer_name,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY total_sales DESC;


-- Top 5 Customers
WITH customer_sales AS (
    SELECT 
        customer_id,
        customer_name,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY customer_id, customer_name
),
ranked_customers AS (
    SELECT *,
           ROW_NUMBER() OVER(ORDER BY total_sales DESC) AS rnk
    FROM customer_sales
)
SELECT 
    customer_id,
    customer_name,
    total_sales
FROM ranked_customers
WHERE rnk <= 5;


-- Customer Segmentation
WITH customer_segments AS (
    SELECT 
        customer_id,
        customer_name,
        SUM(sales) AS total_sales,
        CASE 
            WHEN SUM(sales) > 5000 THEN 'High'
            WHEN SUM(sales) BETWEEN 3000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS segment
    FROM superstore
    GROUP BY customer_id, customer_name
)
SELECT *
FROM customer_segments;


/* =========================================================
   🔹 7. PRODUCT ANALYSIS
   ========================================================= */

-- Top 5 Products
SELECT 
    product_id,
    product_name,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY product_id, product_name
ORDER BY total_sales DESC
LIMIT 5;


-- Loss-Making Products
SELECT 
    product_id,
    product_name,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM superstore
GROUP BY product_id, product_name
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;


/* =========================================================
   🔹 8. REGION ANALYSIS
   ========================================================= */

-- Sales by Region
SELECT 
    region,
    SUM(sales) AS total_sales
FROM superstore
GROUP BY region
ORDER BY total_sales DESC;


-- Most Profitable Region
SELECT 
    region,
    SUM(profit) AS total_profit
FROM superstore
GROUP BY region
ORDER BY total_profit DESC
LIMIT 1;


-- Worst Performing Region
SELECT 
    region,
    SUM(profit) AS total_profit
FROM superstore
GROUP BY region
ORDER BY total_profit ASC
LIMIT 1;