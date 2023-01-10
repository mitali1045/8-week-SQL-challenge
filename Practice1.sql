CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


--1. What is the total amount each customer spent at the restaurant?

select s.customer_id,sum(m.price)
from sales s join menu m on s.product_id = m.product_id
group by s.customer_id;

--2.How many days has each customer visited the restaurant?

select customer_id,count(distinct order_date)
from sales
group by(customer_id);

--3.What was the first item from the menu purchased by each customer?
create function get_product_id(c_id varchar) 
returns table(p_di int) as
$$
	Select product_id
	from sales 
	where customer_id = c_id
	order by order_date
	limit 1;
$$ language sql;


select distinct s.customer_id,m.product_name
from sales s, menu m 
where m.product_id = (select g.p_di from get_product_id(s.customer_id) g);

--Using window function

select distinct customer_id,
min(order_date) over (partition by customer_id)
from sales;

--4.What is the most purchased item on the menu and how many 
--times was it purchased by all customers?

select count(s.product_id),m.product_name
from sales s join menu m on s.product_id = m.product_id
group by m.product_name;

--5.Which item was the most popular for each customer?
select distinct s.customer_id,m.product_name,
max(s.product_id) over(partition by s.customer_id) as popular_item
from sales s join menu m on s.product_id = m.product_id;

--6.Which item was purchased first by the customer after they became a member?
select x.customer_id,x.product_name from 
(select distinct s.customer_id,m.product_name,
rank() over (partition by s.customer_id order by s.order_date) as date_rank
from sales s join members mem on mem.customer_id = s.customer_id join menu m on m.product_id = s.product_id
where mem.join_date < s.order_date and s.customer_id = mem.customer_id and s.product_id = m.product_id) x
where x.date_rank = 1;

--7.Which item was purchased just before the customer became a member?
select x.customer_id,x.product_name from 
(select distinct s.customer_id,m.product_name,
rank() over (partition by s.customer_id order by s.order_date) as date_rank
from sales s join members mem on mem.customer_id = s.customer_id join menu m on m.product_id = s.product_id
where mem.join_date > s.order_date and s.customer_id = mem.customer_id and s.product_id = m.product_id) x
where x.date_rank = 1;

--8.What is the total items and amount spent for each member before they became a member?
select s.customer_id, sum(m.price)
from sales s join menu m on s.product_id = m.product_id join members mem on mem.customer_id = s.customer_id
where s.order_date < mem.join_date
group by(s.customer_id);

--9.If each $1 spent equates to 10 points and sushi has a 
--2x points multiplier - how many points would each customer have?

select s.customer_id,
sum(case when m.product_name  = 'sushi' then m.price * 10 * 2 else m.price * 10 end) points
from sales s join menu m on s.product_id = m.product_id
group by (s.customer_id);

--10.In the first week after a customer joins the program (including their join 
--date) they earn 2x points on all items, not just sushi -
--how many points do customer A and B have at the end of January?

select s.customer_id,
sum(case when m.product_name  = 'sushi' then m.price * 10 * 2 else m.price * 10 end) points
from sales s join menu m on s.product_id = m.product_id
where s.customer_id = 'A' or s.customer_id = 'B'
group by (s.customer_id);


