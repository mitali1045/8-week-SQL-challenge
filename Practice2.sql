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
