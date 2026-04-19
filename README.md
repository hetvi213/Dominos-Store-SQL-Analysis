# Dominos-Store-SQL-Analysis
**Project Overview**

- Project Title: **Domino’s Pizza Store Analysis**
- Level: Beginner to Intermediate
- Database: **dominos**

This project demonstrates SQL techniques used by analysts to explore, clean, and analyze pizza sales and customer data. The analysis focuses on understanding order patterns, revenue, customer behavior, and menu performance to support business decision-making.

<h2> Objectives: </h2>

- Set up a Domino’s pizza database: Create and populate the database with orders, pizzas, and customers.
- Data Cleaning: Identify and remove null or inconsistent records.
- Exploratory Data Analysis (EDA): Understand customer behavior, order trends, and menu performance.
- Business Analysis: Answer stakeholder-driven questions to derive actionable insights.

<h2> Database Structure </h2>

<h3> Tables: </h3>

- orders: Contains order-level information (order_id, custId, order_date, order_time).
- order_details: Contains details of each order (order_detail_id, order_id, pizza_id, quantity).
- pizzas: Contains pizza information (pizza_id, pizza_type_id, size, price).
- pizza_types: Contains pizza type info (pizza_type_id, name, category).
- customers: Contains customer info (custId, first_name, last_name).

<h3> Analysis & Queries </h3>

1. **Orders Volume Analysis:**
  - Total unique orders, orders by month, day-of-week analysis, repeat customers, average orders per customer, cumulative order trend.

2. **Total Revenue from Pizza Sales:** Calculate total revenue from all pizza sales.

3. **Highest-Priced Pizza:** Identify the most expensive pizza on the menu.

4. **Most Common Pizza Size Ordered:** Determine the most frequently ordered pizza size.

5. **Top 5 Most Ordered Pizza Types:**
Find the top 5 pizza types based on quantity sold.
6. **Total Quantity by Pizza Category:**
Calculate total pizzas sold in each category.
7. **Orders by Hour of the Day:**
Understand peak ordering hours to optimize staffing.
8. **Category-Wise Pizza Distribution:**
Analyze category-wise sales and percentage share.
9. **Average Pizzas Ordered per Day:**
Measure daily pizza demand consistency.
10. **Top 3 Pizzas by Revenue:**
Identify pizzas generating the highest revenue.
11. Revenue Contribution per Pizza
Percentage contribution of each pizza to total revenue.
12. Cumulative Revenue Over Time
Monthly cumulative revenue trend since launch.
13. Top 3 Pizzas by Category (Revenue-Based)
Top 3 pizzas by revenue in each category.
14. Top 10 Customers by Spending
Identify the highest-spending customers.
15. Orders by Weekday
Determine busiest days of the week for orders.
16. Average Order Size
Calculate average number of pizzas per order.
17. Seasonal Trends
Analyze sales patterns by month and holidays.
18. Revenue by Pizza Size
Revenue contribution of each pizza size (S, M, L, XL, XXL).
19. Customer Segmentation
Classify customers as High Value or Regular based on spend.
20. Repeat Customer Rate
Percentage of repeat customers versus one-time buyers.

<h2> Key Findings </h2>

- Customer Behavior: High-value and repeat customers identified.
- Order Trends: Peak hours, weekends, and seasonal patterns discovered.
- Menu Insights: Top-selling pizzas, revenue contributors, and popular sizes identified.
- Revenue Analysis: Monthly revenue, cumulative trends, and category-wise contributions analyzed.
- Operational Insights: Average order size, daily pizzas, and staffing optimization recommendations provided.
