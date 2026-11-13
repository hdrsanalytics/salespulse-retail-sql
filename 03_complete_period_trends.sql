
-- Trend analysis uses the complete period January 2017 through August 2018.
-- This excludes partial months from late 2016 and late 2018.

CREATE OR REPLACE VIEW monthly_sales_complete AS
SELECT
    order_month,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(item_revenue) AS revenue
FROM fact_sales
WHERE order_month >= DATE '2017-01-01'
  AND order_month <= DATE '2018-08-01'
GROUP BY order_month;

-- Business question: What was month-over-month revenue growth?
WITH monthly AS (
    SELECT
        order_month,
        order_count,
        revenue
    FROM monthly_sales_complete
),
growth AS (
    SELECT
        order_month,
        order_count,
        revenue,
        LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue
    FROM monthly
)
SELECT
    order_month,
    order_count,
    revenue,
    previous_month_revenue,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_percent
FROM growth
ORDER BY order_month;

-- Business question: What was the three-month moving-average revenue?
SELECT
    order_month,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_average_3_month
FROM monthly_sales_complete
ORDER BY order_month;
