select title, release_year from film;

select count(*) as total_films from film;

select distinct cu.customer_id, cu.first_name, cu.last_name from customer cu
join rental r on cu.customer_id = r.customer_id
group by cu.customer_id;

select f.film_id, f.title, ca.name as category_name from film f
join film_category fc on f.film_id = fc.film_id
join category ca on ca.category_id = fc.category_id
where ca.category_id = 1;

select ca.category_id, count(f.film_id) as num_of_films from film f
join film_category fc on f.film_id = fc.film_id
join category ca on ca.category_id = fc.category_id
group by ca.category_id
order by ca.category_id ASC;

select title, length from film
order by length DESC
limit 5;

select count(*) as num_of_rentals from rental
where rental_date >= '2006-01-01'
	and rental_date < '2006-02-01';

select film_id, title, release_year, length, rental_rate from film
where rental_rate > 3.00;

select distinct c.city from city c
join address a on a.city_id = c.city_id
join customer cu on a.address_id = cu.address_id
order by c.city;

select s.staff_id, s.first_name, s.last_name, count(r.rental_id) as total_rentals from staff s
join rental r on r.staff_id = s.staff_id
group by s.staff_id;

select f.film_id, f.title, count(r.rental_id) as num_of_rentals from film as f
join inventory i on i.film_id = f.film_id
join rental r on i.inventory_id = r.inventory_id
group by f.film_id
order by num_of_rentals DESC
limit 10;

select f.film_id, f.title, sum(p.payment_id) as revenue from film as f
join inventory as i on f.film_id = i.film_id
join rental r on i.inventory_id = r.inventory_id
join payment p on r.rental_id = p.rental_id
group by f.film_id
order by revenue desc;

select c.customer_id, c.first_name, c.last_name, count(r.rental_id) from customer c
join rental r on c.customer_id = r.customer_id
group by c.customer_id
having count(r.rental_id) > 20
order by count(r.rental_id) DESC;

select ca.category_id, ca.name, avg(f.rental_duration) as avg_duration from category as ca
join film_category as fc on ca.category_id = fc.category_id
join film as f on fc.film_id = f.film_id
group by ca.category_id
order by avg_duration desc;

select f.film_id, f.title, f.rental_duration from film f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id
group by f.film_id, f.title
having count(*) filter(
	where r.return_date > r.rental_date + (f.rental_duration || 'days')::interval) = 0;

select ca.category_id, ca.name, count(r.rental_id) as most_popular from category ca
join film_category fc on ca.category_id = fc.category_id
join inventory i on fc.film_id = i.film_id
join rental r on i.inventory_id = r.inventory_id
group by ca.category_id
order by most_popular desc
limit 1;

select extract(year from rental_date) as rental_year, extract(month from rental_date) as rental_month,
count(*) as monthly_rental_count from rental
where rental_date >= '2005-01-01'
	and rental_date < '2007-01-01'
group by rental_year, rental_month
order by rental_year, rental_month;

select c.customer_id, c.first_name, c.last_name, count(distinct ca.category_id) as most_category from customer c
join rental r on r.customer_id = c.customer_id
join inventory i on i.inventory_id = r.inventory_id
join film_category fc on fc.film_id = i.film_id
join category ca on ca.category_id = fc.category_id
group by c.customer_id, c.first_name, c.last_name
having count(distinct ca.category_id) > 5
order by most_category DESC;

select f.film_id, f.title, co.country from film as f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id
join customer c on r.customer_id = c.customer_id
join address a on a.address_id = c.address_id
join city ci on ci.city_id = a.city_id
join country co on co.country_id = ci.country_id
where co.country = 'Canada'
group by f.film_id, f.title, co.country;

select distinct c.customer_id, c.first_name, c.last_name, sum(amount) as total_payment from customer c
join payment p on p.customer_id = c.customer_id
group by c.customer_id, c.first_name, c.last_name
order by total_payment DESC
limit 5;

select * from (
select f.title, count(r.rental_id) as rental_count, rank() over(order by count(r.rental_id) desc) as rental_rank from film f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id
group by f.film_id) ranked_films
where rental_rank > 0;

with monthly_revenue as (
select date_trunc('month', payment_date) as month, extract(YEAR from payment_date) as year, sum(amount) as total_revenue from payment
group by year, date_trunc('month', payment_date)
), ranked_months as(
select year, month, total_revenue, rank() over(partition by year order by total_revenue DESC) as revenue_rank from monthly_revenue)
select year, month, total_revenue from ranked_months
where revenue_rank <= 3
order by year, revenue_rank;

with films_revenue as (
select f.film_id, f.title, sum(p.amount) as total_revenue from film f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id
join payment p on p.rental_id = r.rental_id group by f.film_id)
select film_id, title, total_revenue from films_revenue
where total_revenue > (select avg(total_revenue) from films_revenue)
order by total_revenue DESC;

select c.customer_id, c.first_name, c.last_name, sum(p.amount) as customer_lifetime_value,
rank() over(order by sum(p.amount) desc) as customer_rank
from customer c
join payment p on p.customer_id = c.customer_id
group by c.customer_id, c.first_name, c.last_name
order by customer_lifetime_value desc;

with film_months as (
select distinct f.film_id, f.title, date_trunc('month', r.rental_date) as rental_month from rental r
join inventory i on i.inventory_id = r.inventory_id
join film f on i.film_id = f.film_id), monthly_sequence as(
select film_id, title, rental_month, lag(rental_month) over(partition by film_id order by rental_month) as prev_month 
from film_months)
select distinct title, to_char(prev_month, 'YYYY-MM') AS month_1, to_char(rental_month, 'YYYY-MM') as month_2 from monthly_sequence 
where rental_month = prev_month + interval '1 month'
order by title;

create materialized view film_popularity_by_category as
select c.category_id, c.name as category_name, f.film_id, f.title, count(r.rental_id) as rental_count from category c
join film_category fc on c.category_id = fc.category_id
join film f on fc.film_id = f.film_id
join inventory i on f.film_id = i.film_id
join rental r on i.inventory_id = r.inventory_id
group by c.category_id,c.name,f.film_id,f.title;

refresh materialized view film_popularity_by_category;

select * from film_popularity_by_category
order by rental_count desc;

select *
from film_popularity_by_category
order by category_name, rental_count desc
limit 10;

select * from (
select *, rank() over (partition by category_name order by rental_count desc) as rank_in_category from film_popularity_by_category
) ranked_films
where rank_in_category = 1
order by category_name;