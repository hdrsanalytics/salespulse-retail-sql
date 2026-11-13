
-- Validation 1: Compare row counts and distinct orders at each data grain
SELECT
    (SELECT COUNT(*) FROM fact_sales) AS fact_sales_rows,
    (SELECT COUNT(*) FROM order_summary) AS order_summary_rows,
    (SELECT COUNT(DISTINCT order_id) FROM fact_sales) AS item_orders,
    (SELECT COUNT(DISTINCT order_id) FROM order_summary) AS summary_orders;

-- Validation 2: Check for duplicate order IDs in the one-row-per-order view
SELECT COUNT(*) AS duplicate_order_id_groups
FROM (
    SELECT order_id
    FROM order_summary
    GROUP BY order_id
    HAVING COUNT(*) > 1
) duplicates;

-- Validation 3: Compare revenue totals between both views
SELECT
    ROUND((SELECT SUM(item_revenue) FROM fact_sales), 2) AS fact_sales_revenue,
    ROUND((SELECT SUM(order_revenue) FROM order_summary), 2) AS order_summary_revenue,
    ROUND(
        (SELECT SUM(item_revenue) FROM fact_sales)
        - (SELECT SUM(order_revenue) FROM order_summary),
        2
    ) AS revenue_difference;

-- Validation 4: Count orders by month to identify incomplete months
SELECT
    order_month,
    COUNT(DISTINCT order_id) AS order_count
FROM fact_sales
GROUP BY order_month
ORDER BY order_month;
