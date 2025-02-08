use pizza;
-- show tables;
select * from order_details;
select * from orders;
select * from pizzas;
select * from pizza_types;
-- total pizza sales
select round(sum(od.quantity*p.price),2) as total_sales
from order_details od
left join
pizzas p
on p.pizza_id=od.pizza_id; -- total sales are 817860.05
-- total pizza quantity sold
select sum(quantity) as total_quantity
from order_details; -- total number of pizzas 
-- sales by month
select 
month(o.date) as mnth,
round(sum(od.quantity*p.price),2) as monthly_sales
from orders o
left join order_details od
on o.order_id=od.order_id
left join pizzas p
on p.pizza_id=od.pizza_id
group by mnth
order by 2 desc; -- The top three months with the largest sales are July of $72557.9, 
-- May of $ 71402.75, March of $70397. The bottome three

-- KPI average monthly sales, average total hour
with t as (
select 
count(distinct month(o.date)) as num_of_mnth,
round(sum(od.quantity*p.price),2) as total_sales,
sum(od.quantity) as total_quantity
from orders o
left join order_details od
on o.order_id=od.order_id
left join pizzas p
on p.pizza_id=od.pizza_id)
select *, round(total_sales/num_of_mnth,2) as avg_monthly_sales,
round(total_sales/total_quantity,2) as avg_pizza_price
from t;

-- sales by hours
select 
Hour(o.time) as hr,
round(sum(od.quantity*p.price),2) as monthly_sales
from orders o
left join order_details od
on o.order_id=od.order_id
left join pizzas p
on p.pizza_id=od.pizza_id
group by hr
order by 2 desc; -- The most sales are done during 12h of $111877.9, 13h of $106065.7, 18h og 89296.85.
-- The bottom three hours are 23h of $1121.35, 10h of $303.65, and 9h of $83
--  it's the lunch and 
-- dinner time. The sales around 9, 10, 23 are very low. conside close the stores around that time.

-- 
with t as(
select 
count(distinct(Hour(o.time))) as num_of_hr,
round(sum(od.quantity*p.price),2) as total_sales
from orders o
left join order_details od
on o.order_id=od.order_id
left join pizzas p
on p.pizza_id=od.pizza_id)
select *, round(total_sales/num_of_hr,2) as averge_hour_sales
from t;




select pt.name as pizza_name, 
pt.category,
sum(od.quantity*p.price) as sales
from pizza_types pt
left join pizzas p
on pt.pizza_type_id=p.pizza_type_id
left join order_details od
on p.pizza_id=od.pizza_id
group by pizza_name, category, ingredients
order by 3 desc; -- top names by sales; The top three pizza are all from chicken categories
-- They are thai chicken of $43434.25, Barbecue chicken of $42768, California chicken of $41409.5

-- Top ingredients
select
pt.ingredients,
sum(od.quantity*p.price) as sales
from pizza_types pt
left join pizzas p
on pt.pizza_type_id=p.pizza_type_id
left join order_details od
on p.pizza_id=od.pizza_id
group by ingredients
order by  2 desc; 


-- category sales
select pt.category as category_name, 
round(sum(od.quantity*p.price),2) as sales
from pizza_types pt
left join pizzas p
on pt.pizza_type_id=p.pizza_type_id
left join order_details od
on p.pizza_id=od.pizza_id
group by category_name
order by 2 desc; 
-- Classic is  the best category sellers of $220053.1, 
-- followed by supreme of $208197, chicken of $195919.5, veggie of 193690.45.

-- Category, month pivot
select 
month(o.date) as mnth,
round(sum(case when pt.category="Classic" then od.quantity*p.price end),2) as classic_sales,
round(sum(case when pt.category="Supreme" then od.quantity*p.price end),2) as supreme_sales,
round(sum(case when pt.category="Chicken" then od.quantity*p.price end),2) as chicken_sales,
round(sum(case when pt.category="Veggie" then od.quantity*p.price end),2) as vigge_sales
from orders o 
left join order_details od
on o.order_id=od.order_id
left join pizzas p
on p.pizza_id=od.pizza_id
left join pizza_types pt
on p.pizza_type_id=pt.pizza_type_id
group by mnth;

-- create order_table as temporary table
create temporary table order_table(
select o.order_id, o.date, o.time, od.order_details_id, od.pizza_id, od.quantity
from orders o left join order_details od
on o.order_id=od.order_id);

create temporary table pizza_table(
select p.pizza_id, p.pizza_type_id, p.size,p.price,
pt.name, pt.category,pt.ingredients
from pizzas p left join
pizza_types pt
on p.pizza_type_id=pt.pizza_type_id);

select * from order_table;
-- Category, month pivot
select 
month(o.date) as mnth,
round(sum(case when p.category="Classic" then o.quantity*p.price end),2) as classic_sales,
round(sum(case when p.category="Supreme" then o.quantity*p.price end),2) as supreme_sales,
round(sum(case when p.category="Chicken" then o.quantity*p.price end),2) as chicken_sales,
round(sum(case when p.category="Veggie" then o.quantity*p.price end),2) as vigge_sales
from order_table o
left join pizza_table p
on o.pizza_id=p.pizza_id
group by mnth;

-- sales by ingredients
select pt.name, pt.category,pt.ingredients,
round(sum(od.quantity*p.price),2) as sales,
row_number() over(order by round(sum(od.quantity*p.price),2) desc) as total_rank,
row_number() over (partition by category order by round(sum(od.quantity*p.price),2) desc) as cat_rank
from order_details od
left join pizzas p
on od.pizza_id=p.pizza_id
left join pizza_types pt
on p.pizza_type_id=pt.pizza_type_id
group by pt.name, pt.category,pt.ingredients
order by total_rank; -- top rank are chicken and classic.

-- total sales by size

select 
p.size, 
round(sum(p.price*od.quantity),2) as sales_by_size,
sum(od.quantity) as quantity_by_sales
from order_details od
left join pizzas p
on od.pizza_id=p.pizza_id
group by p.size
order by sales_by_size desc;
-- Large size has the most sales of 375318.7 with the largest quantity sold of 18956,
-- followed by medium size of $249382.25 and quantity sold of 15635, followed
-- by small size of sales of $178076.5 and a quantity of 14403 sold.

-- average size sale and size quantity
with t as(
select
count(distinct p.size) num_of_size, 
round(sum(p.price*od.quantity),2) as total_sales,
sum(od.quantity) as total_quantity
from order_details od
left join pizzas p
on od.pizza_id=p.pizza_id)
select *, 
round(total_sales/num_of_size,2) as avg_sales,
round(total_quantity/num_of_size,2) as avg_quantity
from t
;

-- top pizza by name, monnth
select pt.name,pt.category, p.size, round(sum(p.price*od.quantity),2) as sales
from orders o
left join order_details od
on o.order_id=od.order_id
left join pizzas p
on p.pizza_id=od.pizza_id
left join pizza_types pt
on p.pizza_type_id=pt.pizza_type_id
group by pt.name, pt.category,p.size
order by sales desc;

-- top pizza by category and size and sales
select 
pt.category, 
p.size,
sum(od.quantity) number_of_orders,
round(sum(od.quantity*p.price),2) as sales
from order_details od
left join pizzas p
on od.pizza_id=p.pizza_id
left join pizza_types pt
on p.pizza_type_id=pt.pizza_type_id
group by pt.category, p.size
order by sales desc; -- large and medium size pizzas are well sold. XL and XXL are not well sold
-- remove XL and XXL from the menu. Less small size pizza could be replaced by medium sized since not very popular.

-- total orders order_id
select count(distinct order_details_id), count(distinct order_id), count(*) from order_details;
select count(distinct pizza_type_id), count(distinct Name), count(distinct category),
count(distinct ingredients) from pizza_types;
select count(distinct pizza_id), count(distinct pizza_type_id)
from pizzas;
select distinct pizza_id from pizzas;

with sale as(
select month(o.date) as mnth, 
count(distinct o.order_id) as number_of_orders, 
count(od.order_details_id) as sub_order,
round(sum(od.quantity*p.price),2) as monthly_sales
from orders o left join order_details od
on o.order_id=od.order_id
left join pizzas p
on od.pizza_id=p.pizza_id
group by mnth)
select *, round(monthly_sales/number_of_orders,2) as average_check
from sale;
;

-- number of orders and average paycheck
with sale as(
select month(o.date) as mnth, 
count(distinct o.order_id) as number_of_orders, 
count(od.order_details_id) as details_per_order,
round(sum(od.quantity*p.price),2) as monthly_sales
from orders o left join order_details od
on o.order_id=od.order_id
left join pizzas p
on od.pizza_id=p.pizza_id
group by mnth)
select *, round(monthly_sales/number_of_orders,2) as average_check
from sale;
with t as (
select 
distinct substr(o.time,1,2) as hr,
count(distinct o.order_id) as num_orders,
round(sum(od.quantity*p.price),2) as sales_by_hour
from orders o
left join order_details od
on o.order_id=od.order_id
left join pizzas p
on p.pizza_id=od.pizza_id
group by hr)
select *, sales_by_hour/num_orders as check_per_order_per_hour
from t; -- 9h, 10h, 23h have the lowest sales. The shop should be closed to save more from costs.
-- during the lunch hour 11 and 12, both checks and number of orders are the biggest 
-- Then it's 17, 18 h where checks and number of orders are the second largest.





