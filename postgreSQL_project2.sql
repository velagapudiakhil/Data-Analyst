select employee_id, first_name|| ' ' ||last_name as employee_name, title, max(levels) from employee
group by employee_id
order by max(levels) desc
limit 1;

select billing_country, count(invoice_id) from invoice
group by billing_country
order by count(invoice_id) DESC
LIMIT 1;

select invoice_id, total  from invoice
group by invoice_id
order by total desc
limit 3;

select billing_city as city, sum(total) as total_invoices from invoice
group by billing_city
order by sum(total) desc
limit 1;

select c.customer_id, c.first_name|| ' ' ||c.last_name as customer_name, sum(total) as money_spent from customer c
join invoice i on i.customer_id = c.customer_id
group by c.customer_id
order by money_spent desc
limit 1;

select c.email, c.first_name, c.last_name, g.genre_id, g.name from customer c
join invoice i on i.customer_id = c.customer_id
join invoice_line i_l on i_l.invoice_id = i.invoice_id
join track t on t.track_id = i_l.track_id
join genre g on g.genre_id = t.genre_id
where g.genre_id = '1'
group by c.first_name, c.last_name, c.email, g.genre_id
order by c.email asc;

select a.name as artist_name, count(t.track_id) as total_tracks from artist a
join album al on al.artist_id = a.artist_id
join track t on t.album_id = al.album_id
join genre g on g.genre_id = t.genre_id
where g.name = 'Rock'
group by a.name
order by total_tracks desc
limit 10;

select name, milliseconds from track
where milliseconds > (select avg(milliseconds) from track)
group by name, milliseconds
order by milliseconds desc;

select distinct c.first_name || ' ' ||c.last_name as customer_name, a.name as artist_name, sum(i.total) as total_spent from customer c
join invoice i on i.customer_id = c.customer_id
join invoice_line i_l on i_l.invoice_id = i.invoice_id
join track t on t.track_id = i_l.track_id
join album al on al.album_id = t.album_id
join artist a on a.artist_id = al.artist_id
group by customer_name, artist_name
order by total_spent desc;

with genre_purchases as (select c.country, g.name as genre_name, count(il.invoice_line_id) as purchase_count from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join genre g on g.genre_id = t.genre_id
group by c.country, genre_name),
ranked_genres as (select *, dense_rank() over(partition by country order by purchase_count desc) as rnk from genre_purchases)
select country, genre_name, purchase_count from ranked_genres
where rnk = '1'
order by purchase_count desc;

with customer_spending as (select c.country, c.first_name || ' ' || c.last_name as customer_name, sum(i.total) as total_spent 
from customer c
join invoice i on i.customer_id = c.customer_id
group by c.country, customer_name),
ranked_customers as (select *, dense_rank() over(partition by country order by total_spent desc) as rnk from customer_spending)
select country, customer_name, total_spent from ranked_customers
where rnk = '1'
order by total_spent desc;