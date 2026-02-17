USE coffeeshop_db;

-- =========================================================
-- SUBQUERIES & NESTED LOGIC PRACTICE
-- =========================================================

-- Q1) Scalar subquery (AVG benchmark):
--     List products priced above the overall average product price.
--     Return product_id, name, price.
select product_id, name, price
from products
where price > (select avg(price) from products)
;
 
-- Q2) Scalar subquery (MAX within category):
--     Find the most expensive product(s) in the 'Beans' category.
--     (Return all ties if more than one product shares the max price.)
--     Return product_id, name, price.
select prod_id, prod_name, max_price, prod_price 
from 
(
select p.product_id as prod_id, p.name as prod_name, max(p.price) as max_price, max(p.price) over (partition by c.name) as prod_price 
from products p
join categories c on p.category_id = c.category_id
where c.name = "Beans"
group by p.product_id
order by p.price desc
) prod_max
where max_price = prod_price
;

-- Q3) List subquery (IN with nested lookup):
--     List customers who have purchased at least one product in the 'Merch' category.
--     Return customer_id, first_name, last_name.
--     Hint: Use a subquery to find the category_id for 'Merch', then a subquery to find product_ids.
select cust_id, f_name, l_name 
from 
(
select o.order_id, o.status, oi.order_item_id, ct.category_id, ct.name, cn.customer_id as cust_id, cn.first_name as f_name, cn.last_name as l_name
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
join categories ct on p.category_id = ct.category_id
join customers cn on o.customer_id = cn.customer_id
where ct.name = "Merch" and o.status = "Paid"
) cust_list
;

-- Q4) List subquery (NOT IN / anti-join logic):
--     List products that have never been ordered (their product_id never appears in order_items).
--     Return product_id, name, price.
select p.product_id, p.name, p.price
from products p
where p.product_id not in 
(
select p.product_id
from products p
join order_items oi on p.product_id = oi.product_id
join orders o on oi.order_id = o.order_id
where o.status = "Paid"
)
;

-- Q5) Table subquery (derived table + compare to overall average):
--     Build a derived table that computes total_units_sold per product
--     (SUM(order_items.quantity) grouped by product_id).
--     Then return only products whose total_units_sold is greater than the
--     average total_units_sold across all products.
--     Return product_id, product_name, total_units_sold.
with product_sold as
(
select prod_id, product_name, sum(quantity) over (partition by prod_id) as prod_units_sold, avg(quantity) over() as avg_units_sold
from (
    select p.product_id as prod_id, p.name as product_name, oi.quantity as quantity 
	from order_items oi
	join orders o on oi.order_id = o.order_id
	join products p on oi.product_id = p.product_id
	where o.status = "Paid"
	order by p.name
	) prod_sales
   )
select prod_id, product_name, sum(prod_units_sold)
from product_sold
where prod_units_sold > avg_units_sold
group by prod_id
;
