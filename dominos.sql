CREATE TABLE customers (
    custid integer NOT NULL,
    first_name character varying(8) NOT NULL,
    last_name character varying(7) NOT NULL,
    email character varying(19) NOT NULL,
    phone bigint NOT NULL,
    address character varying(11) NOT NULL,
    city character varying(5) NOT NULL,
    state character varying(6) NOT NULL,
    postal_code integer NOT NULL
);

CREATE TABLE pizza_types (
    pizza_type_id character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    category character varying(50) NOT NULL,
    ingredients text NOT NULL
);

CREATE TABLE pizzas (
    pizza_id character varying(14) NOT NULL,
    pizza_type_id character varying(12) NOT NULL,
    size character varying(3) NOT NULL,
    price numeric(5,2) NOT NULL
);

CREATE TABLE orders (
    order_id integer NOT NULL,
    order_date date NOT NULL,
    order_time character varying(8) NOT NULL,
    custid integer NOT NULL,
    status character varying(9) NOT NULL
);

CREATE TABLE order_details (
    order_details_id integer NOT NULL,
    order_id integer NOT NULL,
    pizza_id character varying(14) NOT NULL,
    quantity integer NOT NULL
);

-- 1. PIZZAS TABLE
ALTER TABLE pizzas 
    ADD CONSTRAINT pizzas_pkey PRIMARY KEY (pizza_id),
    ADD CONSTRAINT fk_pizzas_pizza_types FOREIGN KEY (pizza_type_id) REFERENCES pizza_types(pizza_type_id);
	
-- 2. ORDERS TABLE
ALTER TABLE orders 
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id),
    ADD CONSTRAINT fk_orders_customers FOREIGN KEY (custid) REFERENCES customers(custid);

-- 3. PIZZA_TYPES TABLE
ALTER TABLE pizza_types 
    ADD CONSTRAINT pizza_types_pkey PRIMARY KEY (pizza_type_id);

-- 4. ORDER_DETAILS TABLE
ALTER TABLE order_details 
    ADD CONSTRAINT order_details_pkey PRIMARY KEY (order_details_id),
    ADD CONSTRAINT fk_details_pizzas FOREIGN KEY (pizza_id) REFERENCES pizzas(pizza_id),
    ADD CONSTRAINT fk_details_orders FOREIGN KEY (order_id) REFERENCES orders(order_id);

select * from customers;
select * from orders;
select * from order_details;
select * from pizzas;
select * from pizza_types;

select quantity from order_details where quantity < 2;



/*
-----------------------
-- Dominos Store
-- Analysis & Reports
-----------------------

1. Orders Volume Analysis Queries

Stakeholder (Operations Manager):

"We are trying to understand our order volume in detail so we can measure store performance and benchmark growth. 
Instead of just knowing the total number of unique orders, I’d like a deeper breakdown:

1. What is the total number of unique orders placed so far?
2. How has this order volume changed month-over-month and year-over-year?
3. Can we identify peak and off-peak ordering days?
4. How do order volumes vary by day of the week (e.g., weekends vs weekdays)?
5. What is the average number of orders per customer?
6. Who are our top repeat customers driving the order volume?
7. Can you also project the expected order growth trend based on historical data?"
*/

-- 1. Count the total number of unique orders
SELECT COUNT(DISTINCT order_id) AS total_unique_orders 
FROM orders;

-- 2. Break down orders by month and year
WITH monthly_orders AS (
	SELECT DATE_TRUNC ('month', order_date) AS month,
	COUNT (order_id) AS order_count
	FROM orders
	GROUP BY month
)
SELECT month, order_count, 
	LAG (order_count) OVER (ORDER BY month) AS prev_count,
	ROUND (100 * (order_count - LAG (order_count) OVER (ORDER BY month)) / 
	NULLIF(LAG (order_count) OVER (ORDER BY month), 0), 2) AS month_growth
FROM monthly_orders
ORDER BY month;

-- OR

SELECT 
    EXTRACT(YEAR FROM order_date) AS order_year,
    EXTRACT(MONTH FROM order_date) AS order_month,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- 3. Find day-wise order distribution
SELECT 
    TO_CHAR(order_date, 'Day') AS day_of_week,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY day_of_week, EXTRACT(DOW FROM order_date)
ORDER BY EXTRACT(DOW FROM order_date);

-- 4. Compute average orders per customer
SELECT 
    ROUND (COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT custid), 2) AS avg_orders_per_customer
FROM orders;

-- OR

SELECT 
    ROUND (COUNT(order_id)::numeric / COUNT(DISTINCT custid), 2) AS avg_orders_per_customer
FROM orders;

-- 5. Identify repeat customers and their order frequency
SELECT 
    custid, 
    COUNT(order_id) AS order_count
FROM orders
GROUP BY custid
ORDER BY order_count DESC;

-- OR

SELECT 
    custid, 
    COUNT(order_id) AS order_frequency
FROM orders
GROUP BY custid
HAVING COUNT(order_id) > 1
ORDER BY order_frequency DESC;

-- 6. Use window functions to calculate month-over-month growth %
WITH monthly_orders AS (
	SELECT DATE_TRUNC ('month', order_date) AS month,
	COUNT (order_id) AS order_count
	FROM orders
	GROUP BY month
)
SELECT month, 
	order_count, 
	LAG (order_count) OVER (ORDER BY month) AS prev_count,
	ROUND (100 * (order_count - LAG (order_count) OVER (ORDER BY month)) / 
	NULLIF(LAG (order_count) OVER (ORDER BY month), 0), 2) AS month_growth
FROM monthly_orders
ORDER BY month;

SELECT order_date,
	COUNT (order_id) AS daily_orders,
	SUM (COUNT (order_id)) OVER (ORDER BY order_date) AS cumulative_frequency
FROM orders
GROUP BY order_date
ORDER BY order_date;

-- OR

WITH monthly_counts AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY 1
)
SELECT 
    month,
    order_count,
    LAG(order_count) OVER (ORDER BY month) AS prev_month_count,
    ROUND(((order_count - LAG(order_count) OVER (ORDER BY month))::numeric / 
    LAG(order_count) OVER (ORDER BY month)) * 100, 2) AS mom_growth_pct
FROM monthly_counts;

-- 7. Build a trend projection using cumulative counts
SELECT 
    order_date,
    COUNT(order_id) OVER (ORDER BY order_date) AS cumulative_order_count
FROM orders
ORDER BY order_date;


/*
2. Total Revenue from Pizza Sales

Stakeholder (Finance Team):
"We need to report monthly revenue to management. 
Can you calculate the total revenue generated from all pizza sales, 
considering price * quantity from each order?"

Analyst Task: Join order_details with pizzas and sum (price * quantity).
*/

SELECT 
	SUM (od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id;


/*
3. Highest-Priced Pizza

Stakeholder (Menu Manager):
"Our premium pizzas must be correctly priced. Can you find out which pizza
has the highest price on our menu and confirm its category and size?"

Analyst Task: Query the pizzas table for the maximum price, joining with pizza_types for details.
*/

SELECT 
	pt.name,
	pt.category,
	p.size,
	CONCAT ('$', p.price) AS price
FROM pizzas p
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC;


/*
4. Most Common Pizza Size Ordered

Stakeholder (Logistics Manager):
"To optimize packaging and raw material supply, I need to know which 
pizza size (S, M, L, XL, XXL) is ordered the most."

Analyst Task: Count and group orders by pizza size from pizzas + order_details.
*/

SELECT 
	p.size,
	COUNT (*) AS total
FROM order_details od
JOIN pizzas p ON Od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY total DESC;


/*
5. Top 5 Most Ordered Pizza Types

Stakeholder (Product Head):
"We want to promote our top-selling pizzas. Can you provide the top 5 pizza
types ordered by quantity, along with the exact number of units sold?"

Analyst Task: Join order_details with pizza_types, group by pizza name, and rank top 5.
*/

SELECT 
	pt.name,
	SUM (od.quantity) AS total_qty
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_qty DESC
LIMIT 5;


/*
6. Total Quantity by Pizza Category

Stakeholder (Marketing Manager):
"We run promotions based on categories (Classic, Veggie, Supreme, Chicken, etc.). 
Can you calculate the total number of pizzas sold in each category 
so we can plan targeted campaigns?"

Analyst Task: Join pizzas with pizza_types and sum quantities by category.
*/

SELECT 
	pt.category,
	SUM (od.quantity) AS total_qty
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_qty DESC;


/*
7. Orders by Hour of the Day

Stakeholder (Operations Head):
"When are customers ordering the most? Do they prefer lunch (12-2 PM), 
evenings (6-9 PM), or late-night? Please give me a distribution 
of orders by hour of the day so we can adjust staffing."
*/

SELECT 
	TO_CHAR (order_TIME::time, 'HH24:00') AS order_hour,
	COUNT (*) AS order_count
FROM orders
GROUP BY order_hour
ORDER BY order_hour;


/*
8. Category-Wise Pizza Distribution

Stakeholder (Product Strategy Team):
"Which categories (like Veggie, Chicken, Supreme) dominate 
our menu sales? Can you prepare a breakdown of orders per category with percentage share?"

Analyst Task: Join tables and calculate share of each category.
*/

WITH category_counts AS (
    SELECT 
        pt.category, 
        COUNT(od.order_id) AS total_orders
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category
)
SELECT 
    category, 
    total_orders,
    ROUND((total_orders::numeric / SUM(total_orders) OVER()) * 100, 2) AS percentage_share
FROM category_counts
ORDER BY percentage_share DESC;


/*
9. Average Pizzas Ordered per Day

Stakeholder (CEO):
"I want to see if our daily demand is consistent. 
Can you group orders by date and tell me the average number of pizzas ordered per day?"

Analyst Task: Aggregate by order_date, calculate total pizzas per day, then average.
*/

SELECT 
    ROUND(AVG(pizzas_per_day), 0) AS avg_pizzas_per_day
FROM (
    SELECT 
        o.order_date, 
        SUM(od.quantity) AS pizzas_per_day
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.order_date
) AS daily_totals;


/*
10. Top 3 Pizzas by Revenue

Stakeholder (Finance Team):
"We need to know which pizzas are our biggest revenue drivers. 
Please provide the top 3 pizzas by revenue generated."

Analyst Task: Calculate revenue per pizza (price * quantity) and rank top 3.
*/

SELECT 
    pt.name, 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_revenue DESC
LIMIT 3;

OR 

WITH revenue AS (
	SELECT 
		pt.name,
		ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
		RANK() OVER (ORDER BY total_revenue) DESC AS rank
	FROM order_details od
	JOIN pizzas p ON od.pizza_id = p.pizza_id
	JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
	GROUP BY pt.name
)
SELECT 
	name, 
	total_revenue
FROM revenue
WHERE rank <=3 


/*
Advanced Analysis

11. Revenue Contribution per Pizza

Stakeholder (CFO):
"For our revenue mix analysis, I need to know what percentage of 
total revenue each pizza contributes. 
This will show which items carry the business."

Analyst Task: Divide revenue of each pizza by total revenue, express in %.
*/

SELECT 
		pt.name,
		ROUND(SUM(od.quantity * p.price), 2) AS total_revenue,
		CONCAT (ROUND(100 * SUM(od.quantity * p.price) / 
		SUM(SUM(od.quantity * p.price)) OVER(), 2), '%') AS per_contribution
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY per_contribution DESC;


/*
12. Cumulative Revenue Over Time

Stakeholder (Board of Directors):
"We want to see how our cumulative revenue has grown month by month 
since launch. Can you prepare a cumulative revenue trend line?"

Analyst Task: Aggregate revenue by date/month and calculate running total.
*/

SELECT 
	order_date,
	SUM(daily_revenue) OVER (ORDER BY order_date) AS cumulative_freq
FROM (
	SELECT 
		o.order_date,
		daily_revenue,
		SUM(od.quantity * p.price) as daily_revenue
	FROM ORDERS o
	JOIN order_details od ON o.order_id = od.order_id
	JOIN pizzas p ON od.pizza_id = p.pizza_id
	GROUP BY o.order_date
) t;


/*
13. Top 3 Pizzas by Category (Revenue-Based)

Stakeholder (Product Head):
"Within each pizza category, which 3 pizzas bring the most revenue? 
This will help us decide which pizzas to promote or expand."

Analyst Task: Partition by category, calculate revenue per pizza, rank top 3.
*/

WITH pizza_revenue AS (
    SELECT 
        pt.category,
        pt.name,
        ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
),
ranked_pizzas AS (
    SELECT 
        category,
        name,
        total_revenue,
        RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS rnk
    FROM pizza_revenue
)
SELECT 
    category,
    name,
    total_revenue
FROM ranked_pizzas
WHERE rnk <= 3;


/*
Extended Business Case Studies

14. Top 10 Customers by Spending

Stakeholder (Customer Retention Manager):
"Who are our top 10 customers based on total spend? 
We want to reward them with loyalty offers."
*/

SELECT 
	c.custid,
    c.first_name || ' ' || c.last_name AS name, 
    ROUND(SUM(od.quantity * p.price), 2) AS total_spent
FROM customers c
JOIN orders o ON c.custid = o.custid
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY c.custid, name 
ORDER BY total_spent DESC
LIMIT 10;


/*
15. Orders by Weekday

Stakeholder (Marketing Team):
"Which days of the week are busiest for orders? 
Do customers order more on weekends?"
*/

SELECT 
    TO_CHAR(order_date, 'Day') AS day_of_week, 
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY day_of_week, EXTRACT(DOW FROM order_date)
ORDER BY EXTRACT(DOW FROM order_date);


/*
16. Average Order Size

Stakeholder (Supply Chain Manager):
"What's the average number of pizzas per order? 
This helps us in planning inventory and staffing."
*/

SELECT 
    ROUND(AVG(pizzas_per_order), 2) AS avg_pizzas_per_order
FROM (
    SELECT 
        order_id, 
        SUM(quantity) AS pizzas_per_order
    FROM order_details
    GROUP BY order_id
) AS order_summary;


/*
17. Seasonal Trends

Stakeholder (Operations Manager):
"Do we see peak sales in certain months or holidays? 
This will help us manage seasonal demand."
*/

SELECT 
	EXTRACT (MONTH FROM order_date) AS month,
	COUNT (*) AS total_orders
FROM orders
GROUP BY month
ORDER BY MONTH;

OR 

SELECT 
    TO_CHAR(order_date, 'Month') AS month_name, 
    COUNT(order_id) AS total_orders,
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY month_name, EXTRACT(MONTH FROM order_date)
ORDER BY EXTRACT(MONTH FROM order_date);


/*
18. Revenue by Pizza Size

Stakeholder (Finance Head):
"What is the revenue contribution of each pizza 
size (S, M, L, XL, XXL)?"
*/

SELECT 
    p.size, 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue,
    ROUND(
        (SUM(od.quantity * p.price) / 
        SUM(SUM(od.quantity * p.price)) OVER()) * 100, 2
    ) AS revenue_percentage
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY total_revenue DESC;


/*
19. Customer Segmentation

Stakeholder (Customer Insights Team):
"Do our high-value customers prefer premium pizzas or regular pizzas? 
We want to personalize marketing."
*/


WITH cust_spend AS (
    SELECT 
        c.custid,
        SUM(od.quantity * p.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.custid = o.custid
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY c.custid
)
SELECT 
	
    CASE 
		WHEN total_spent > 500 THEN 'High Value' 
			ELSE 'Regular' 
    END AS segment,
	COUNT (*) AS customer_count
FROM cust_spend 
GROUP BY segment;
	

OR

WITH cust_spend AS (
    SELECT 
        c.custid,
        SUM(od.quantity * p.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.custid = o.custid
    JOIN order_details od ON o.order_id = od.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY c.custid
),
customer_segments AS (
    SELECT 
        custid,
        CASE 
            WHEN total_spent > 500 THEN 'High Value' 
            ELSE 'Regular' 
        END AS segment
    FROM cust_spend
)
SELECT 
    cs.segment,
    pt.category,
    SUM(od.quantity) AS pizzas_ordered
FROM customer_segments cs
JOIN orders o ON cs.custid = o.custid
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY cs.segment, pt.category
ORDER BY cs.segment, pizzas_ordered DESC;


/*
20. Repeat Customer Rate

Stakeholder (CRM Head - Customer Relationship Manager):
"We want to measure customer loyalty. Can you calculate the percentage 
of repeat customers (customers who placed more than one order) 
versus one-time buyers? This will help us design retention campaigns."

Analyst Task:
From the orders table, count distinct customers.
Count how many customers have more than one order.
Calculate repeat rate = (repeat customers / total customers) * 100.
*/

WITH cust_orders AS (
    SELECT 
        custId, 
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    GROUP BY custId
)
SELECT 
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate
FROM cust_orders;

OR

WITH customer_order_counts AS (
    SELECT 
        custid, 
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY custid
)
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        (SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)::numeric / 
        COUNT(*)) * 100, 2
    ) AS repeat_customer_rate_pct
FROM customer_order_counts;
