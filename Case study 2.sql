CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

--A. Pizza metrics

--1.How many pizzas were ordered?

select count(*) from customer_orders;

--2. How many unique customer orders were made?

select count(distinct customer_id) from customer_orders;

--3.How many successful orders were delivered by each runner?

select count(*) from runner_orders where cancellation is null or cancellation = '' or cancellation = 'null';

--4.How many of each type of pizza was delivered?

select customer.pizza_id,count(customer.pizza_id)
from customer_orders customer join runner_orders run on customer.order_id = run.order_id
where run.cancellation is null or run.cancellation = '' or run.cancellation = 'null'
group by (customer.pizza_id);

--5.How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id,
sum(case when pizza_id = 1 then 1 else 0 end) as meat_lovers,
sum(case when pizza_id = 2 then 1 else 0 end) as vegetarian
from customer_orders
group by (customer_id);

--6.What was the maximum number of pizzas delivered in a single order?

select count(pizza_id),order_id
from customer_orders
group by(order_id)
order by count(pizza_id) desc limit 1;

--7. For each customer, how many delivered pizzas had at least 1 change and 
--how many had no changes?

SELECT customer_id,
sum(case when exclusions is not null or exclusions <> 'null' or exclusions <> '' or extras <> '' or extras is not null or extras <> 'null' then 1 else 0 end) as change,
sum(case when exclusions is null or exclusions = '' or exclusions = 'null' or extras = '' or extras is null or extras = 'null' then 1 else 0 end) as nochange
from customer_orders customer join runner_orders run on customer.order_id = run.order_id
where run.cancellation is null or run.cancellation = '' or run.cancellation = 'null'
group by (customer_id);

--8.How many pizzas were delivered that had both exclusions and extras?
WITH cte_cleaned_customer_orders AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE WHEN exclusions IN ('null', '') THEN NULL else 1 END AS exclusions,
    CASE WHEN extras IN ('null', '') THEN NULL else 1 END AS extras,
    order_time
  FROM pizza_runner.customer_orders
)
SELECT
count(*)
FROM cte_cleaned_customer_orders
WHERE exclusions IS NOT NULL and extras IS NOT NULL;

--9.What was the total volume of pizzas ordered for each hour of the day?

select count(order_id), date_part('hour',order_time::Timestamp) as hour
from customer_orders
group by hour;

--10.What was the volume of orders for each day of the week?
select count(order_id), date_part('day',order_time::Timestamp) as day
from customer_orders
group by day;

--B. Runner and Customer Experience

--1.How many runners signed up 
--for each 1 week period? (i.e. week starts 2021-01-01)

select count(runner_id), date_part('week',registration_date::Timestamp) as week
from runners
group by week;


--2.What was the average time in minutes it took for each runner to arrive 
--at the Pizza Runner HQ to pickup the order?

select ro.runner_id,avg(date_part('minutes',ro.pickup_time::Timestamp) -  date_part('minutes',cs.order_time::Timestamp))
from customer_orders cs join runner_orders ro on cs.order_id = ro.order_id
where ro.pickup_time <> 'null'
group by ro.runner_id;

--3.Is there any relationship between the number of pizzas
--and how long the order takes to prepare?

select cs.customer_id,count(cs.order_id),avg(date_part('minutes',ro.pickup_time::Timestamp) - date_part('minutes',cs.order_time::Timestamp))
from customer_orders cs join runner_orders ro on cs.order_id = ro.order_id
where ro.pickup_time <> 'null'
group by cs.customer_id;

--4. What was the average distance travelled for each customer?

select cs.customer_id, avg(ro.distance)
from customer_orders cs join runner_orders ro on cs.order_id = ro.order_id
group by(cs.customer_id);

--5. What was the difference between the longest and shortest delivery 
--times for all orders?

select cs.order_id, max(date_part('minute',cs.order_time::Timestamp)) - min(date_part('minute',cs.order_time::Timestamp))
from customer_orders cs join runner_orders ro on cs.order_id = ro.order_id
where ro.duration is not null or ro.duration <> 'null'
group by(cs.order_id)
order by cs.order_id;

--6.What was the average speed for each runner for each delivery and 
--do you notice any trend for these values?

select ro.order_id,count(ro.order_id) as no_of_orders,ro.runner_id,avg(substring(ro.distance from '[0-9]+')::numeric/substring(ro.duration from '[0-9]+')::numeric) as avg_speed
from customer_orders cs join runner_orders ro on cs.order_id = ro.order_id
where (ro.duration is not null or ro.duration <> 'null') and (ro.distance is not null or ro.distance <> 'null')
group by(ro.order_id,ro.runner_id)
order by no_of_orders desc;

--7.What is the successful delivery percentage for each runner?

with q1 as (Select r1.runner_id, count(r1.runner_id) as exp_count
  from runner_orders r1  
  where r1.cancellation = '' or r1.cancellation is null or r1.cancellation = 'null'
  group by r1.runner_id),
 q2 as (Select r2.runner_id, count(r2.runner_id) as norm_count
  from runner_orders r2 
  group by r2.runner_id)
select q1.runner_id, (q1.exp_count::float/q2.norm_count::float)*100 as success_percent
from q1,q2
where q1.runner_id = q2.runner_id;


--C. Ingredient Optimisation

--1.What are the standard ingredients for each pizza?
drop function ingredients_

create or replace function ingredients_(pid int)
returns setof text as 
$$
declare
topping text[];
top text;
begin
	for topping in
		select array[toppings] from pizza_recipes where pizza_id = pid
		loop
			foreach top in array topping
			loop
				return query select topping_name 
				from pizza_toppings
				where top = topping_id::text;
			end loop;
		end loop;
end;
$$ language plpgsql;

select * from ingredients_(1);

--2.What was the most commonly added extra?

select extras,count(extras) as extras_count
from customer_orders
where extras <> '' and extras is not null and extras <> 'null'
group by(extras)
order by extras_count desc limit 1;

--3.What was the most common exclusion?

select exclusions,count(exclusions) as exclusions_count
from customer_orders
where exclusions <> '' and exclusions is not null and exclusions <> 'null'
group by(exclusions)
order by exclusions_count desc limit 1;

--4. Generate an order item for each record in the customers_orders 
--table in the format of one of the following:

create table customer_orders_mt(
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

--a. Meat lovers
insert into customer_orders_mt values
()

--5. Generate an alphabetically ordered comma separated ingredient list for 
--each pizza order from the customer_orders table and add a 2x in 
--front of any relevant ingredients

--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


create view temp_data as 
select order_id,customer_orders.pizza_id,toppings,extras
from customer_orders join pizza_recipes on customer_orders.pizza_id = pizza_recipes.pizza_id
where (string_to_array(extras, ',')::text[]) <@ (string_to_array(toppings, ',')::text[])
and extras <> ''
order by order_id;

select *
from (select order_id,pizza_id,toppings,extras, 
	  concat(toppings,',',unnest(string_to_array(extras, ',')::text[])) as extra_toppings
	  from temp_data)q; 
	  
	  
--6.What is the total quantity of each ingredient used in all delivered pizzas
--sorted by most frequent first?

select topping, count(*) as count_topping
from customer_orders join pizza_recipes on customer_orders.pizza_id = pizza_recipes.pizza_id
cross join lateral unnest(string_to_array(toppings, ',')::int[]) x(topping)
group by x.topping
order by count_topping desc;

--D. Pricing and Ratings

--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges
--for changes - how much money has Pizza Runner made so far if there are no delivery fees?

select runner_id,
sum(case when pizza_id = 1 then 12 end) +
sum(case when pizza_id = 2 then 10 end) as Total 
from customer_orders join runner_orders on customer_orders.order_id = runner_orders.order_id
group by runner_id;

--2.What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra

select runner_id,
sum(case when pizza_id = 1 then 12 end) +
sum(case when pizza_id = 2 then 10 end) +
(Select sum(cardinality(string_to_array(extras,',')::int[])) 
 from customer_orders 
 where extras is not null and extras <> 'null' and extras <> '') as Total 
from customer_orders join runner_orders on customer_orders.order_id = runner_orders.order_id
group by runner_id;

--3.The Pizza Runner team now wants to add an additional ratings system that allows
--customers to rate their runner, how would you design an additional table for this
--new dataset - generate a schema for this new table and insert your own data for 
--ratings for each successful customer order between 1 to 5.



CREATE TABLE runner_ratings (
  "runner_id" INTEGER,
  "order_id" INTEGER,
	"rating" INTEGER,
	"customer_id"  INTEGER
);

