use sample;
TRUNCATE TABLE sales;
CREATE TABLE sales (
    employee   VARCHAR(50),
    department VARCHAR(50),
    amount     INT
);
INSERT INTO sales values ('Alice', 'Sales', 100),('River','OPS',150),('Bob','Sales',200),('Carol','Sales',150),('Cherry','OPS',150),('Dave','IT',300),('Eve','IT',250);
SELECT * FROM sales;

-- RUNNING TOTAL
SELECT employee, department, amount, 
	SUM(amount) OVER(ORDER BY amount) as running_total
FROM sales;

-- COMPARE EACH ROW TO GROUP AVG
SELECT employee, department, amount,
	AVG(amount) OVER(PARTITION BY department ORDER BY department) as dept_avg
FROM sales;

-- RANKING
SELECT employee, department, amount,
	RANK() OVER (ORDER BY amount DESC) as ranking
FROM sales;

-- RANKING BY DEPARTMENT
SELECT employee, department, amount,
	RANK() OVER (PARTITION BY department ORDER BY amount DESC) as ranking
FROM sales;

-- TOP 1 IN EVERY DEPARTMENT
SELECT * FROM
	(SELECT *,
		RANK() OVER (PARTITION BY department ORDER BY amount DESC) as ranking
	FROM sales) ranked
WHERE ranking = 1;

-- RANKING, DENSE RANKING, ROW NUMBER
SELECT employee, department, amount,
	RANK() OVER (ORDER BY amount DESC) as ranking,
    DENSE_RANK() OVER (ORDER BY amount DESC) as dense_ranking,
    ROW_NUMBER() OVER (ORDER BY amount DESC) as row_numbers
FROM sales;

-- RANKING, DENSE RANKING, ROW NUMBER BY department
SELECT employee, department, amount,
	RANK() OVER (PARTITION BY department ORDER BY amount DESC) as ranking,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY amount DESC) as dense_ranking,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY amount DESC) as row_numbers
FROM sales;

-- LAG
SELECT employee, amount,
       LAG(amount) OVER (ORDER BY amount) AS previous_amount,
       amount - LAG(amount) OVER (ORDER BY amount) AS diff_from_prev
FROM sales;

-- LEAD
SELECT employee, amount,
       LEAD(amount) OVER (ORDER BY amount) AS NEXT_amount,
       amount - LEAD(amount) OVER (ORDER BY amount) AS diff_from_NEXT
FROM sales;

CREATE TABLE employees (
    employee_id   INT PRIMARY KEY,
    employee_name VARCHAR(50),
    department    VARCHAR(50),
    hire_date     DATE,
    salary        INT
);
INSERT INTO employees VALUES
(1,  'Alice',  'Sales',     '2019-03-15', 55000),
(2,  'Bob',    'Sales',     '2020-06-01', 62000),
(3,  'Carol',  'Sales',     '2021-01-10', 58000),
(4,  'Dave',   'IT',        '2018-11-20', 75000),
(5,  'Eve',    'IT',        '2019-07-05', 80000),
(6,  'Frank',  'IT',        '2022-02-14', 70000),
(7,  'Grace',  'HR',        '2020-09-01', 50000),
(8,  'Heidi',  'HR',        '2021-05-30', 52000),
(9,  'Ivan',   'Marketing', '2019-12-01', 60000),
(10, 'Judy',   'Marketing', '2022-08-15', 65000);

SELECT * FROM employees;

CREATE TABLE monthly_sales (
    sale_id     INT PRIMARY KEY,
    employee_id INT,
    sale_month  DATE,
    revenue     INT
);
INSERT INTO monthly_sales VALUES
(1, 1, '2023-01-01', 12000),
(2, 1, '2023-02-01', 15000),
(3, 1, '2023-03-01', 11000),
(4, 2, '2023-01-01', 20000),
(5, 2, '2023-02-01', 18000),
(6, 2, '2023-03-01', 22000),
(7, 3, '2023-01-01', 9000),
(8, 3, '2023-02-01', 13000),
(9, 3, '2023-03-01', 14000);

SELECT * FROM monthly_sales;

-- Questions
-- Ranking functions

-- Rank all employees by salary (highest first) using ROW_NUMBER().
SELECT *, ROW_NUMBER() OVER (ORDER BY salary DESC) as Ranks FROM employees;

-- Rank employees within each department by salary using RANK().
SELECT *, RANK() OVER (ORDER BY salary DESC) as Ranks_ FROM employees;

-- Same as above but using DENSE_RANK() — compare the output difference when there's a tie.
SELECT *,
	ROW_NUMBER() OVER (ORDER BY salary DESC) as Ranks,
	RANK() OVER (ORDER BY salary DESC) as Ranks_,
    DENSE_RANK() OVER (ORDER BY salary DESC) as Dense_Ranks_
FROM employees;

-- Split employees into 4 salary buckets (quartiles) using NTILE(4).
SELECT employee_name, salary,
       NTILE(4) OVER (ORDER BY salary DESC) AS quartile
FROM employees;

-- Aggregate window functions
-- 5. Show each employee's salary next to the average salary of their department.
SELECT *,
	AVG(salary) OVER (PARTITION BY department) as dept_avg
FROM employees;

-- 6. Show each employee's salary next to the max salary in the whole company.
SELECT *,
	MAX(salary) OVER () as max_sal
FROM employees;

-- 7. Count how many employees are in each department, shown next to every row (without using GROUP BY).
SELECT *,
	COUNT(employee_id) OVER (PARTITION BY department) as dept_emp_count
FROM employees;

-- Running totals / order-based aggregates
-- 8. For monthly_sales, calculate a running total of revenue for each employee, ordered by sale_month.
SELECT *, 
	SUM(revenue) OVER(PARTITION BY employee_id ORDER BY sale_month) as running_total
FROM monthly_sales;

-- 9. Calculate the running total of revenue across the whole company (not per employee) ordered by month.
SELECT *, 
	SUM(revenue) OVER(ORDER BY sale_month) as running_total
FROM monthly_sales;

-- LAG / LEAD
-- 10. For each employee's monthly sales, show the previous month's revenue next to the current one.
SELECT *,
	LAG(revenue) OVER (PARTITION BY employee_id ORDER BY employee_id) as prev_revenue
FROM monthly_sales;

-- 11. Calculate the month-over-month change in revenue for each employee (current − previous).
-- month-over-month GROWTH
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(sale_month, '%Y-%m-01') AS sale_month,
        ROUND(SUM(revenue),2) AS revenue
    FROM monthly_sales
    GROUP BY DATE_FORMAT(sale_month, '%Y-%m-01')
)
SELECT 
    sale_month,
    revenue,
    ROUND(LAG(revenue) OVER (ORDER BY sale_month),2) AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY sale_month),2) AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY sale_month)) * 100.0 
        / NULLIF(LAG(revenue) OVER (ORDER BY sale_month), 0), 2
    ) AS pct_growth
FROM monthly_revenue
ORDER BY sale_month;

-- month-over-month CHANGE
SELECT employee_id, sale_month, revenue,
       revenue - LAG(revenue) OVER (PARTITION BY employee_id ORDER BY sale_month) AS mom_change
FROM monthly_sales;

SELECT 
    sale_month,
    revenue,
    ROUND(LAG(revenue) OVER (ORDER BY sale_month),2) AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY sale_month),2) AS mom_change
FROM monthly_sales
ORDER BY sale_month;

-- 12. Show the next month's revenue using LEAD().
SELECT *,
	LEAD(revenue) OVER (PARTITION BY employee_id ORDER BY sale_month) as next_revenue
FROM monthly_sales;

-- FIRST_VALUE / LAST_VALUE
-- 13. For each employee, show their first month's revenue next to every row.
SELECT employee_id, sale_month, revenue,
       FIRST_VALUE(revenue) OVER (PARTITION BY employee_id ORDER BY sale_month) AS first_month_revenue
FROM monthly_sales;

-- 14. For each department, find the highest-paid employee's name shown next to every row in that department.
SELECT employee_name, department, salary,
       FIRST_VALUE(employee_name) OVER (
           PARTITION BY department ORDER BY salary DESC
       ) AS top_earner_in_dept
FROM employees;

-- Mixed / challenge
-- 15. Find the top 2 earners in each department (hint: rank first, then filter with a subquery or CTE, since you can't WHERE directly on a window function).
WITH ranked AS (
    SELECT employee_name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT employee_name, department, salary
FROM ranked
WHERE rnk <= 2;

-- 16. Find employees whose salary is above their department's average.
WITH dept_avg AS 
	(SELECT *,
		AVG(salary) OVER(PARTITION BY department) as avg_
	FROM employees)
SELECT * FROM dept_avg
where salary > avg_;

-- Try a few of these — start with #1, #2, and #5, they're the easiest — and send me your queries whenever you want me to check them or explain where it went wrong.

-- SQL evaluates roughly in this order:

-- FROM / JOIN → WHERE → GROUP BY → HAVING → SELECT (window functions happen here) → ORDER BY

-- So window functions run after joins and grouping, but before the final ORDER BY. This is also why you can't filter directly on a window function result using WHERE (that's why question #15 earlier needs a subquery/CTE) — WHERE happens before window functions are calculated.

-- Want to try writing one yourself — say, "show each employee's name, department, revenue, and how it compares to the department average revenue" — using the join?


