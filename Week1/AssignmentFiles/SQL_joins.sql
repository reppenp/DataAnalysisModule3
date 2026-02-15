USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
select p.name as product_name, c.name as category_name, p.price 
from products p inner join categories c on p.category_id = c.category_id;

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
select oi.order_item_id, oi.order_id, o.order_datetime, s.name as store_name, p.name as product_name, oi.quantity, p.price, (oi.quantity * p.price) as line_total 
from order_items oi
join orders o on oi.order_id = o.order_id
join products p on oi.product_id = p.product_id
join stores s on o.store_id = s.store_id
order by o.order_datetime, order_id;

-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
select o.order_id, concat(c.first_name, " ", c.last_name) as customer_name, s.name as store_name, o.order_datetime, sum(oi.quantity * p.price) as order_total
from orders o
join customers c on o.customer_id = c.customer_id
join stores s on o.store_id = s.store_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
group by o.order_id;
 
-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
-- ALL CUSTOMERS HAVE PLACED AN ORDER - NULL RESULT SET
select c.customer_id, c.first_name, c.last_name, c.city, c.state, o.order_id
from customers c left join orders o on c.customer_id = o.customer_id
where o.order_id IS NULL;

-- TESTED WITH
select * from customers;

-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.

with ranked_units_sold as
(
select store_name, product_name, total_units,
    row_number() over (partition by store_name order by total_units desc) as rn
from (
    select s.name as store_name, p.name as product_name, sum(oi.quantity) as total_units
    from orders o
    join order_items oi on o.order_id = oi.order_id
    join products p on oi.product_id = p.product_id
    join stores s on o.store_id = s.store_id
    where o.status = "Paid"
    group by s.name, p.name
	) store_prod_units
)
select store_name, product_name, total_units
from ranked_units_sold
where rn = 1;

-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
select s.name, p.name, i.on_hand
    from inventory i
    join products p on i.product_id = p.product_id
    join stores s on i.store_id = s.store_id
    where i.on_hand < 12;

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
select s.name, concat(e.first_name, " ",e.last_name) as manager_name, e.hire_date
    from employees e
    join stores s on e.store_id = s.store_id
    where e.title = "Manager";

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
with product_revenue as
(
select product_name, sum(quantity), sum(line_total) as ttl_prod_rev, (sum(line_total) / sum(quantity)) as avg_prod_rev
from (
    select oi.order_item_id, o.status, p.name as product_name, oi.quantity as quantity, p.price, (oi.quantity * p.price) as line_total 
	from order_items oi
	join orders o on oi.order_id = o.order_id
	join products p on oi.product_id = p.product_id
	where o.status = "Paid"
	order by p.name
	) prod_rev
group by product_name
)
select product_name, ttl_prod_rev, overall_avg_prod_rev
from (
	select product_name, ttl_prod_rev, avg(avg_prod_rev) over() as overall_avg_prod_rev 
	from product_revenue
) overall_prod_rev
where ttl_prod_rev > overall_avg_prod_rev
;

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.

with cust_orders as
(
select customer_name, order_date, row_number() over (partition by customer_name order by order_date desc) as last_orderdate
from
(
	select o.order_id, concat(c.first_name, " ", c.last_name) as customer_name, s.name as store_name, o.order_datetime as order_date, sum(oi.quantity * p.price) as order_total
	from orders o
	join customers c on o.customer_id = c.customer_id
	join stores s on o.store_id = s.store_id
	join order_items oi on o.order_id = oi.order_id
	join products p on oi.product_id = p.product_id
	group by o.order_id
) order_hist
)
select customer_name, order_date, last_orderdate
from cust_orders
where last_orderdate = 1
;

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
select store_name, category_name, sum(item_qty) as total_units, sum(item_rev) as total_revenue
from
(
select s.name as store_name, c.name as category_name, p.name as product_name, oi.order_item_id as item_no, oi.quantity as item_qty, (p.price * oi.quantity) as item_rev
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
join stores s on o.store_id = s.store_id
join categories c on p.category_id = c.category_id
where o.status = "Paid"
) prod_mix
group by store_name, category_name
;
