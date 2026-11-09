
-- SalesPulse SQL Query Library
-- Database views required:
-- fact_sales and order_summary

-- Q01: What is total revenue?
SELECT ROUND(SUM(item_revenue), 2) AS total_revenue
FROM fact_sales;


-- Q02: How many orders and unique customers exist?
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM order_summary;


-- Q03: What is the average order value?
SELECT ROUND(AVG(order_revenue), 2) AS average_order_value
FROM order_summary;


-- Q04: What is monthly revenue?
SELECT
    order_month,
    ROUND(SUM(item_revenue), 2) AS monthly_revenue
FROM fact_sales
GROUP BY order_month
ORDER BY order_month;


-- Q05: Which product categories generate the most revenue?
SELECT
    category,
    ROUND(SUM(item_revenue), 2) AS category_revenue,
    COUNT(DISTINCT order_id) AS order_count
FROM fact_sales
GROUP BY category
ORDER BY category_revenue DESC
LIMIT 15;


-- Q06: Which customer states generate the most revenue?
SELECT
    customer_state,
    ROUND(SUM(order_revenue), 2) AS total_revenue,
    COUNT(*) AS order_count
FROM order_summary
GROUP BY customer_state
ORDER BY total_revenue DESC;


-- Q07: How many orders exist in each status?
SELECT
    order_status,
    COUNT(*) AS order_count
FROM order_summary
GROUP BY order_status
ORDER BY order_count DESC;


-- Q08: Which payment methods are most common?
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(TRY_CAST(payment_value AS DOUBLE)), 2) AS payment_total
FROM payments
GROUP BY payment_type
ORDER BY order_count DESC;


-- Q09: What is the average customer review score?
SELECT
    ROUND(AVG(TRY_CAST(review_score AS DOUBLE)), 2) AS average_review_score,
    COUNT(*) AS review_count
FROM reviews;


-- Q10: Which sellers generate the most revenue?
SELECT
    seller_id,
    ROUND(SUM(item_revenue), 2) AS seller_revenue,
    COUNT(DISTINCT order_id) AS order_count
FROM fact_sales
GROUP BY seller_id
ORDER BY seller_revenue DESC
LIMIT 15;


-- Q11: Which customers generate the most lifetime revenue?
WITH customer_metrics AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS order_count,
        SUM(order_revenue) AS lifetime_revenue,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM order_summary
    GROUP BY customer_unique_id
)
SELECT *
FROM customer_metrics
ORDER BY lifetime_revenue DESC
LIMIT 20;


-- Q12: When did each customer first purchase?
WITH first_orders AS (
    SELECT
        customer_unique_id,
        MIN(order_date) AS first_order_date
    FROM order_summary
    GROUP BY customer_unique_id
)
SELECT *
FROM first_orders
ORDER BY first_order_date;


-- Q13: What is the repeat-customer rate?
WITH customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS order_count
    FROM order_summary
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS repeat_customer_percent
FROM customer_order_counts;


-- Q14: How many days does delivery take on average?
WITH delivered_orders AS (
    SELECT
        order_id,
        delivery_days
    FROM order_summary
    WHERE order_status = 'delivered'
      AND delivery_days IS NOT NULL
)
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    MIN(delivery_days) AS fastest_delivery_days,
    MAX(delivery_days) AS slowest_delivery_days
FROM delivered_orders;


-- Q15: Which states have the highest late-delivery rate?
WITH state_delivery AS (
    SELECT
        customer_state,
        COUNT(*) AS delivered_orders,
        SUM(late_flag) AS late_orders
    FROM order_summary
    WHERE order_status = 'delivered'
      AND delivery_days IS NOT NULL
    GROUP BY customer_state
)
SELECT
    customer_state,
    delivered_orders,
    late_orders,
    ROUND(
        100.0 * late_orders / delivered_orders,
        2
    ) AS late_delivery_percent
FROM state_delivery
WHERE delivered_orders >= 100
ORDER BY late_delivery_percent DESC;


-- Q16: Which categories have the highest freight costs?
WITH category_freight AS (
    SELECT
        category,
        SUM(freight_value) AS total_freight,
        SUM(item_revenue) AS total_revenue
    FROM fact_sales
    GROUP BY category
)
SELECT
    category,
    ROUND(total_freight, 2) AS total_freight,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(
        100.0 * total_freight / NULLIF(total_revenue, 0),
        2
    ) AS freight_percent_of_revenue
FROM category_freight
ORDER BY total_freight DESC
LIMIT 15;


-- Q17: Which seller states generate the most revenue?
WITH seller_state_revenue AS (
    SELECT
        s.seller_state,
        SUM(fs.item_revenue) AS revenue,
        COUNT(DISTINCT fs.order_id) AS order_count
    FROM fact_sales fs
    LEFT JOIN sellers s
        ON fs.seller_id = s.seller_id
    GROUP BY s.seller_state
)
SELECT
    seller_state,
    ROUND(revenue, 2) AS revenue,
    order_count
FROM seller_state_revenue
ORDER BY revenue DESC;


-- Q18: How do monthly customers and orders change?
WITH monthly_activity AS (
    SELECT
        order_month,
        COUNT(DISTINCT order_id) AS order_count,
        COUNT(DISTINCT customer_unique_id) AS customer_count,
        SUM(item_revenue) AS revenue
    FROM fact_sales
    GROUP BY order_month
)
SELECT
    order_month,
    order_count,
    customer_count,
    ROUND(revenue, 2) AS revenue
FROM monthly_activity
ORDER BY order_month;


-- Q19: What revenue comes from each order status?
WITH status_metrics AS (
    SELECT
        order_status,
        COUNT(*) AS order_count,
        SUM(order_revenue) AS revenue
    FROM order_summary
    GROUP BY order_status
)
SELECT
    order_status,
    order_count,
    ROUND(revenue, 2) AS revenue
FROM status_metrics
ORDER BY revenue DESC;


-- Q20: Which states have the best review scores?
WITH review_by_order AS (
    SELECT
        order_id,
        AVG(TRY_CAST(review_score AS DOUBLE)) AS review_score
    FROM reviews
    GROUP BY order_id
),
state_reviews AS (
    SELECT
        os.customer_state,
        AVG(r.review_score) AS average_review_score,
        COUNT(*) AS reviewed_orders
    FROM order_summary os
    INNER JOIN review_by_order r
        ON os.order_id = r.order_id
    GROUP BY os.customer_state
)
SELECT
    customer_state,
    ROUND(average_review_score, 2) AS average_review_score,
    reviewed_orders
FROM state_reviews
WHERE reviewed_orders >= 100
ORDER BY average_review_score DESC;


-- Q21: What is month-over-month revenue growth?
WITH monthly_revenue AS (
    SELECT
        order_month,
        SUM(item_revenue) AS revenue
    FROM fact_sales
    GROUP BY order_month
),
previous_month AS (
    SELECT
        order_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY order_month
        ) AS previous_revenue
    FROM monthly_revenue
)
SELECT
    order_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(
        100.0 * (revenue - previous_revenue)
        / NULLIF(previous_revenue, 0),
        2
    ) AS mom_growth_percent
FROM previous_month
ORDER BY order_month;


-- Q22: What is the cumulative revenue over time?
WITH monthly_revenue AS (
    SELECT
        order_month,
        SUM(item_revenue) AS revenue
    FROM fact_sales
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ),
        2
    ) AS running_revenue
FROM monthly_revenue
ORDER BY order_month;


-- Q23: What are the top three categories in each month?
WITH monthly_category_revenue AS (
    SELECT
        order_month,
        category,
        SUM(item_revenue) AS revenue
    FROM fact_sales
    GROUP BY order_month, category
),
ranked_categories AS (
    SELECT
        order_month,
        category,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY order_month
            ORDER BY revenue DESC
        ) AS category_rank
    FROM monthly_category_revenue
)
SELECT
    order_month,
    category,
    ROUND(revenue, 2) AS revenue,
    category_rank
FROM ranked_categories
WHERE category_rank <= 3
ORDER BY order_month, category_rank;


-- Q24: What is the product rank within each category?
WITH product_revenue AS (
    SELECT
        category,
        product_id,
        SUM(item_revenue) AS revenue
    FROM fact_sales
    GROUP BY category, product_id
)
SELECT
    category,
    product_id,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (
        PARTITION BY category
        ORDER BY revenue DESC
    ) AS product_rank
FROM product_revenue
ORDER BY category, product_rank;


-- Q25: What is the three-month moving-average revenue?
WITH monthly_revenue AS (
    SELECT
        order_month,
        SUM(item_revenue) AS revenue
    FROM fact_sales
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS three_month_moving_average
FROM monthly_revenue
ORDER BY order_month;


-- Q26: What is each customer's order sequence?
SELECT
    customer_unique_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_date
    ) AS customer_order_number
FROM order_summary
ORDER BY customer_unique_id, order_date;


-- Q27: How many days passed between customer orders?
WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM order_summary
)
SELECT
    customer_unique_id,
    order_id,
    order_date,
    previous_order_date,
    DATE_DIFF(
        'day',
        previous_order_date,
        order_date
    ) AS days_between_orders
FROM customer_orders
WHERE previous_order_date IS NOT NULL
ORDER BY customer_unique_id, order_date;
