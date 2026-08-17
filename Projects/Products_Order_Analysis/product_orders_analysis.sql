use sample;
select * from product_orders limit 5;

-- Beginner
-- 1. Write a query to select all orders with OrderStatus = 'Cancelled'.
SELECT 
    *
FROM
    product_orders
WHERE
    OrderStatus = 'Cancelled';
    
-- 2. Find the total number of distinct customers who placed an order.
SELECT DISTINCT
    COUNT(customerid) AS Total_Customers
FROM
    product_orders;
    
-- 3. List all orders placed in the Electronics category, sorted by OrderDate descending.
SELECT 
    *
FROM
    product_orders
WHERE
    category = 'Electronics'
ORDER BY orderdate DESC;

-- 4. Get the average UnitPrice of all products in the table.
SELECT 
    ROUND(AVG(unitprice), 2) AS Average_UnitPrice
FROM
    product_orders;

-- Intermediate
-- 5. Find the total revenue grouped by Region.
SELECT 
    ROUND(SUM(totalprice), 2) AS Total_Revenue
FROM
    product_orders
GROUP BY region;

-- 6. Find the top 5 customers by total amount spent.
SELECT 
	customerid,
    customername,
    ROUND(SUM(totalprice), 2) AS Total_amount_spent
FROM
    product_orders
GROUP BY customerid , customername
ORDER BY Total_amount_spent DESC
LIMIT 5;

-- 7. Write a query to find the number of orders per month (use OrderDate) for the year 2025.
SELECT 
    EXTRACT(MONTH FROM OrderDate) AS order_month,
    COUNT(*) AS num_orders
FROM product_orders
WHERE EXTRACT(YEAR FROM OrderDate) = 2025
GROUP BY EXTRACT(MONTH FROM OrderDate)
ORDER BY order_month;

-- 8. Find all products that have never been ordered with Quantity greater than 5 (use a subquery or NOT IN).
SELECT DISTINCT
    productid, productname
FROM
    product_orders
WHERE
    productid NOT IN 
    (SELECT DISTINCT
            productid
        FROM
            product_orders
        WHERE
            quantity > 5); 
            
-- Advanced
-- 9. Write a query using a window function (RANK() or ROW_NUMBER()) to find the top 3 highest-value orders within each Region.
SELECT *
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY Region ORDER BY TotalPrice DESC) AS rnk
    FROM product_orders
) ranked
WHERE rnk <= 3;

-- 10. Calculate the month-over-month growth in revenue (use LAG() to compare each month's total revenue to the previous month).
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(OrderDate, '%Y-%m-01') AS order_month,
        ROUND(SUM(TotalPrice),2) AS revenue
    FROM product_orders
    GROUP BY DATE_FORMAT(OrderDate, '%Y-%m-01')
)
SELECT 
    order_month,
    revenue,
    ROUND(LAG(revenue) OVER (ORDER BY order_month),2) AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY order_month),2) AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month)) * 100.0 
        / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0), 2
    ) AS pct_growth
FROM monthly_revenue
ORDER BY order_month;

-- 11. Find customers who ordered from more than 3 different categories (use GROUP BY + HAVING COUNT(DISTINCT Category) > 3).
SELECT CustomerID, CustomerName, COUNT(DISTINCT Category) AS num_categories
FROM product_orders
GROUP BY CustomerID, CustomerName
HAVING COUNT(DISTINCT Category) > 3
ORDER BY num_categories DESC;

-- 12. Write a query to compute a running (cumulative) total of revenue ordered by OrderDate using a window function (SUM() OVER (ORDER BY ...)).
SELECT 
    OrderDate,
    TotalPrice,
    SUM(TotalPrice) OVER (ORDER BY OrderDate 
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM orders
ORDER BY OrderDate;