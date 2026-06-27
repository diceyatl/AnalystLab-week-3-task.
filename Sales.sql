-- Preview the data
SELECT TOP 10 * FROM sales_data_sample;

-- Rows count and key stats
SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT ORDERNUMBER)     AS unique_orders,
    COUNT(DISTINCT CUSTOMERNAME)    AS unique_customers,
    COUNT(DISTINCT COUNTRY)         AS unique_countries
FROM sales_data_sample;

-- All shipped orders by sales value
SELECT
    ORDERNUMBER,
    CUSTOMERNAME,
    ORDERDATE,
    SALES,
    STATUS
FROM sales_data_sample
WHERE STATUS = 'Shipped'
ORDER BY SALES DESC;

-- Total revenue by product line
SELECT
    PRODUCTLINE,
    COUNT(DISTINCT ORDERNUMBER) AS total_orders,
    SUM(QUANTITYORDERED) AS total_units,
    ROUND(SUM(SALES), 2) AS total_revenue
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY total_revenue DESC;

-- Yearly revenue summary
SELECT
    YEAR_ID                         AS year,
    COUNT(DISTINCT ORDERNUMBER)     AS total_orders,
    ROUND(SUM(SALES), 2)            AS annual_revenue
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY YEAR_ID;

-- Countries with revenue above $100,000
SELECT
    COUNTRY,
    ROUND(SUM(SALES), 2) AS total_revenue
FROM sales_data_sample
GROUP BY COUNTRY
HAVING SUM(SALES) > 100000
ORDER BY total_revenue DESC;

-- Average sales per deal size
SELECT
    DEALSIZE,
    COUNT(*) AS total_line_items,
    ROUND(AVG(SALES), 2) AS avg_sale_value,
    ROUND(SUM(SALES), 2) AS total_revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY total_revenue DESC;

-- Order lines with their order totals
SELECT TOP 20
    s.ORDERNUMBER,
    s.CUSTOMERNAME,
    s.PRODUCTLINE,
    s.SALES AS line_sales,
    order_totals.order_total
FROM sales_data_sample s
INNER JOIN (
    SELECT
        ORDERNUMBER,
        ROUND(SUM(SALES), 2) AS order_total
    FROM sales_data_sample
    GROUP BY ORDERNUMBER
) AS order_totals ON s.ORDERNUMBER = order_totals.ORDERNUMBER
ORDER BY order_totals.order_total DESC, s.ORDERNUMBER, s.ORDERLINENUMBER;

-- Products ordered in both 2003 and 2004
SELECT DISTINCT PRODUCTCODE, PRODUCTLINE
FROM sales_data_sample
WHERE PRODUCTCODE IN (
    SELECT PRODUCTCODE FROM sales_data_sample WHERE YEAR_ID = 2003
)
AND PRODUCTCODE IN (
    SELECT PRODUCTCODE FROM sales_data_sample WHERE YEAR_ID = 2004
)
ORDER BY PRODUCTLINE, PRODUCTCODE;

-- Rank products by revenue within each product line
SELECT
    PRODUCTLINE,
    PRODUCTCODE,
    product_revenue,
    ROW_NUMBER() OVER (
        PARTITION BY PRODUCTLINE
        ORDER BY product_revenue DESC
    ) AS rank_in_line
FROM (
    SELECT
        PRODUCTLINE,
        PRODUCTCODE,
        ROUND(SUM(SALES), 2) AS product_revenue
    FROM sales_data_sample
    GROUP BY PRODUCTLINE, PRODUCTCODE
) AS product_totals
ORDER BY PRODUCTLINE, rank_in_line;

-- Top 15 customers by revenue with RANK and DENSE_RANK
SELECT TOP 15
    CUSTOMERNAME,
    COUNTRY,
    total_revenue,
    RANK()       OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS dense_revenue_rank
FROM (
    SELECT
        CUSTOMERNAME,
        COUNTRY,
        ROUND(SUM(SALES), 2) AS total_revenue
    FROM sales_data_sample
    GROUP BY CUSTOMERNAME, COUNTRY
) AS customer_totals
ORDER BY revenue_rank;

-- Year-to-date running revenue by month
SELECT
    YEAR_ID,
    MONTH_ID,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        PARTITION BY YEAR_ID
        ORDER BY MONTH_ID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS ytd_revenue
FROM (
    SELECT
        YEAR_ID,
        MONTH_ID,
        ROUND(SUM(SALES), 2) AS monthly_revenue
    FROM sales_data_sample
    GROUP BY YEAR_ID, MONTH_ID
) AS monthly_agg
ORDER BY YEAR_ID, MONTH_ID;

-- Month over month revenue change using LAG
SELECT
    YEAR_ID,
    MONTH_ID,
    monthly_revenue,
    LAG(monthly_revenue) OVER (
        ORDER BY YEAR_ID, MONTH_ID
    ) AS prev_month_revenue,
    ROUND(monthly_revenue - LAG(monthly_revenue) OVER (
        ORDER BY YEAR_ID, MONTH_ID
    ), 2) AS mom_change
FROM (
    SELECT
        YEAR_ID,
        MONTH_ID,
        ROUND(SUM(SALES), 2) AS monthly_revenue
    FROM sales_data_sample
    GROUP BY YEAR_ID, MONTH_ID
) AS monthly_agg
ORDER BY YEAR_ID, MONTH_ID;

-- Top 10 customers by lifetime revenue
SELECT TOP 10
    CUSTOMERNAME,
    COUNTRY,
    COUNT(DISTINCT ORDERNUMBER) AS total_orders,
    SUM(QUANTITYORDERED) AS total_units_bought,
    ROUND(SUM(SALES), 2) AS lifetime_revenue
FROM sales_data_sample
GROUP BY CUSTOMERNAME, COUNTRY
ORDER BY lifetime_revenue DESC;

-- Revenue by quarter and year
SELECT
    YEAR_ID AS year,
    QTR_ID  AS quarter,
    COUNT(DISTINCT ORDERNUMBER) AS total_orders,
    ROUND(SUM(SALES), 2) AS quarterly_revenue
FROM sales_data_sample
GROUP BY YEAR_ID, QTR_ID
ORDER BY YEAR_ID, QTR_ID;

-- Order status breakdown
SELECT
    STATUS,
    COUNT(DISTINCT ORDERNUMBER) AS order_count,
    ROUND(SUM(SALES), 2) AS total_sales_value,
    ROUND(
        100.0 * COUNT(DISTINCT ORDERNUMBER) /
        SUM(COUNT(DISTINCT ORDERNUMBER)) OVER ()
    , 2) AS pct_of_orders
FROM sales_data_sample
GROUP BY STATUS
ORDER BY order_count DESC;

-- Revenue by territory
SELECT
    TERRITORY,
    COUNTRY,
    ROUND(SUM(SALES), 2) AS total_revenue,
    COUNT(DISTINCT CUSTOMERNAME) AS unique_customers
FROM sales_data_sample
WHERE TERRITORY IS NOT NULL AND TERRITORY != ''
GROUP BY TERRITORY, COUNTRY
ORDER BY total_revenue DESC;

-- Deal size preference per country
SELECT
    COUNTRY,
    DEALSIZE,
    COUNT(DISTINCT ORDERNUMBER) AS total_orders,
    ROUND(SUM(SALES), 2) AS total_revenue
FROM sales_data_sample
GROUP BY COUNTRY, DEALSIZE
ORDER BY COUNTRY, total_revenue DESC;

-- High MSRP but low volume products
SELECT
    PRODUCTCODE,
    PRODUCTLINE,
    MSRP,
    SUM(QUANTITYORDERED) AS total_units_sold,
    ROUND(SUM(SALES), 2) AS total_revenue
FROM sales_data_sample
GROUP BY PRODUCTCODE, PRODUCTLINE, MSRP
HAVING MSRP > 150 AND SUM(QUANTITYORDERED) < 200
ORDER BY MSRP DESC;