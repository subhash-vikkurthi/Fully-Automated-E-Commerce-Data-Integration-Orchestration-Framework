
-- gender wise sales 
CREATE OR REPLACE VIEW VW_REGIONAL_GENDER_SALES AS
SELECT
    C.REGION,
    C.GENDER,
    COUNT(DISTINCT F.ORDER_ID) AS TOTAL_ORDERS,
    SUM(F.QUANTITY) AS TOTAL_QUANTITY,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES,
    SUM(F.PROFIT) AS TOTAL_PROFIT
FROM DIM_CUSTOMERS C
JOIN FACT_SALES_DETAILS F
    ON C.CUSTOMER_ID = F.CUSTOMER_ID
WHERE C.IS_CURRENT = TRUE
GROUP BY C.REGION, C.GENDER;

select * from VW_REGIONAL_GENDER_SALES;

-- TOP OREDER GENRATED CITYS
CREATE OR REPLACE VIEW VW_TOP_ORDER_CITIES AS
SELECT
    C.CITY,
    C.REGION,
    COUNT(DISTINCT F.ORDER_ID) AS TOTAL_ORDERS,
    COUNT(DISTINCT C.CUSTOMER_ID) AS TOTAL_CUSTOMERS,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES,
    SUM(F.PROFIT) AS TOTAL_PROFIT
FROM DIM_CUSTOMERS C
JOIN FACT_SALES_DETAILS F
    ON C.CUSTOMER_ID = F.CUSTOMER_ID
WHERE C.IS_CURRENT = TRUE
GROUP BY C.CITY, C.REGION;

SELECT * FROM VW_TOP_ORDER_CITIES;


--Most & Least Profitable Products

CREATE OR REPLACE VIEW VW_PRODUCT_PROFITABILITY AS
SELECT P.PRODUCT_ID, P.PRODUCT_CATEGORY, P.PRODUCT_NAME,
    SUM(F.QUANTITY) AS TOTAL_QUANTITY_SOLD,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES,
    SUM(F.PROFIT) AS TOTAL_PROFIT,

    CASE
        WHEN SUM(F.PROFIT) > 10000 THEN 'High Performing'
        WHEN SUM(F.PROFIT) > 0 THEN 'Average Performing'
        ELSE 'Low Performing'
    END AS PRODUCT_PERFORMANCE

FROM DIM_PRODUCTS P 
join dim_customers c on c.customer_id = f.customer_id
GROUP BY PRODUCT_ID,PRODUCT_CATEGORY,PRODUCT_NAME;

SELECT * FROM VW_PRODUCT_PROFITABILITY;


-- Year-Wise Sales & Profit Analysis

CREATE OR REPLACE VIEW VW_YEARLY_SALES_PROFIT AS
SELECT
    YEAR(O.ORDER_DATE) AS SALES_YEAR,
    COUNT(DISTINCT O.ORDER_ID) AS TOTAL_ORDERS,
    SUM(F.QUANTITY) AS TOTAL_QUANTITY_SOLD,
    SUM(F.TOTAL_AMOUNT) AS TOTAL_SALES,
    SUM(F.PROFIT) AS TOTAL_PROFIT,
    SUM(F.SHIPPING_COST) AS TOTAL_SHIPPING_COST,

    ROUND(AVG(F.CUSTOMER_SATISFACTION), 2)
        AS AVG_CUSTOMER_SATISFACTION

FROM DIM_ORDERS O
JOIN FACT_SALES_DETAILS F
    ON O.ORDER_ID = F.ORDER_ID
WHERE O.IS_CURRENT = TRUE
GROUP BY YEAR(O.ORDER_DATE);

SELECT * FROM VW_YEARLY_SALES_PROFIT;


-- Product Shipping Performance Analysis
CREATE OR REPLACE VIEW VW_PRODUCT_SHIPPING_ANALYSIS AS
SELECT
    P.PRODUCT_ID,
    P.PRODUCT_CATEGORY,
    F.PRODUCT_NAME,

    SUM(F.QUANTITY) AS TOTAL_QUANTITY_SOLD,

    ROUND(AVG(F.DAYS_TO_SHIP), 2) AS AVG_SHIPPING_DAYS,
    ROUND(AVG(F.SHIPPING_COST), 2) AS AVG_SHIPPING_COST,

    ROUND(AVG(F.CUSTOMER_SATISFACTION), 2)
        AS AVG_CUSTOMER_SATISFACTION,

    CASE
        WHEN AVG(F.DAYS_TO_SHIP) > 7 THEN 'High Shipping Time'
        WHEN AVG(F.DAYS_TO_SHIP) > 3 THEN 'Moderate Shipping Time'
        ELSE 'Fast Shipping'
    END AS SHIPPING_CATEGORY

FROM DIM_PRODUCTS P
JOIN FACT_SALES_DETAILS F
    ON P.PRODUCT_ID = F.PRODUCT_ID
GROUP BY
    P.PRODUCT_ID,
    P.PRODUCT_CATEGORY,
    F.PRODUCT_NAME;

SELECT * FROM VW_PRODUCT_SHIPPING_ANALYSIS;

--Which customers place the highest number of orders?

select c.customer_id, c.customer_name, count(distinct f.order_id) as total_orders
from fact_sales_details f
join dim_customers c on c.customer_id = f.customer_id
group by c.customer_id, c.customer_name
order by total_orders desc;

--What percentage of total revenue comes from each customer?


select c.customer_id, c.customer_name,
       sum(f.total_amount) as customer_revenue,
       round(sum(f.total_amount) * 100.0 / sum(sum(f.total_amount)) over (), 2) as pct_of_total_revenue
from fact_sales_details f
join dim_customers c on c.customer_id = f.customer_id
group by c.customer_id, c.customer_name
order by customer_revenue desc;

--How can customers be segmented into High, Medium, and Low-value customers based on their spending?

with customer_spend as (
    select c.customer_id, c.customer_name, sum(f.total_amount) as total_spent
    from fact_sales_details f
    join dim_customers c on c.customer_id = f.customer_id
    group by c.customer_id, c.customer_name
)
select *,
    case
        when total_spent >= (select percentile_cont(0.75) within group (order by total_spent) from customer_spend) then 'High'
        when total_spent >= (select percentile_cont(0.25) within group (order by total_spent) from customer_spend) then 'Medium'
        else 'Low'
    end as customer_segment
from customer_spend
order by total_spent desc;


--Which products are most frequently purchased by customers?

select p.PRODUCT_NAME,
       count(f.order_id) as times_purchased,
       sum(f.quantity) as total_quantity_sold
from fact_sales_details f
join dim_products p on p.product_id = f.product_id
group by p.product_name
order by times_purchased desc;

--What is the year-over-year or month-over-month sales growth?


with monthly_sales as (
    select date_trunc('month', order_date) as sales_month, sum(total_amount) as total_revenue
    from fact_sales_details f
    join dim_orders o on f.order_id = o.order_id
    group by sales_month
)
select sales_month, total_revenue,
       lag(total_revenue) over (order by sales_month) as prev_month_revenue,
       round((total_revenue - lag(total_revenue) over (order by sales_month)) * 100.0
             / lag(total_revenue) over (order by sales_month), 2) as mom_growth_pct
from monthly_sales
order by sales_month;

--Which day, month, quarter, or year generates the highest sales?

with yearly_sales as (
    select year( o.order_date) as sales_year, sum(f.total_amount) as total_revenue
    from fact_sales_details f 
    join dim_orders o on f.order_id = o.order_id
    group by sales_year
    
)
select sales_year, total_revenue,
       lag(total_revenue) over (order by sales_year) as prev_year_revenue,
       round((total_revenue - lag(total_revenue) over (order by sales_year)) * 100.0
             / lag(total_revenue) over (order by sales_year), 2) as yoy_growth_pct
from yearly_sales
order by sales_year;



select dayname(o.order_date) as day_of_week, sum(f.total_amount) as total_revenue
from fact_sales_details f 
join dim_orders o on f.order_id = o.order_id
group by day_of_week
order by total_revenue desc;

select quarter(o.order_date) as quarter_num, sum(f.total_amount) as total_revenue
from fact_sales_details f 
join dim_orders o on f.order_id = o.order_id
group by quarter_num
order by total_revenue desc;


--Which products and categories contribute the most to overall business revenue, and what is their percentage contribution?

-- product level
select p.product_name, p.product_category,
       sum(f.total_amount) as product_revenue,
       round(sum(f.total_amount) * 100.0 / sum(sum(f.total_amount)) over (), 2) as pct_contribution
from fact_sales_details f
join dim_products p on p.product_id = f.product_id
group by p.product_name, p.product_category
order by product_revenue desc;

-- category level
select p.PRODUCT_CATEGORY,
       sum(f.total_amount) as category_revenue,
       round(sum(f.total_amount) * 100.0 / sum(sum(f.total_amount)) over (), 2) as pct_contribution
from fact_sales_details f
join dim_products p on p.product_id = f.product_id
group by p.PRODUCT_CATEGORY
order by category_revenue desc;