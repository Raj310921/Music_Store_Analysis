select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;



/**************************************************************************************************************/ 


-- Question Set 1 (Easy)

-- 1. Who is the senior most employee based on job title?

SELECT FIRST_NAME || ' ' || LAST_NAME FULL_NAME, LEVELS
FROM EMPLOYEE
ORDER BY LEVELS DESC
LIMIT 1;


-- 2. Which countries have the most Invoices?

select  billing_country as country, count(invoice_id) Total_invoices from invoice
group by billing_country
order by Total_invoices desc
limit 1;


-- 3. What are top 3 values of invoice total amount?

select total total_amount from invoice
order by total_amount desc
limit 3;



/* 4. Which city has the best customers? 
We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals. */


select billing_city city, sum(total) total_amount from invoice
group by city
order by total_amount desc
limit 1;



/* 5. Who is the best customer? 
The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money. */

select i.customer_id cust_id, c.first_name || ' ' || c.last_name Cust_name, sum(i.total) total_amount from invoice i
join customer c
on i.customer_id = c.customer_id
group by cust_id, Cust_name
order by total_amount
limit 1;


/**************************************************************************************************************/ 


-- Question Set 2 (Moderate)

/* 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */


select distinct c.customer_id, c.first_name||' '||c.last_name Full_name, c.email, g."name" Genre_name from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on t.track_id = il.track_id
join genre g on g.genre_id = t.genre_id
where g."name" = 'Rock'
order by c.email;



/* 2. Let's invite the artists who have given us the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */


select  art.name Artist_name, count(t.track_id) track_count
from track t
join album a on a.album_id = t.album_id
join artist art on art.artist_id = a.artist_id
group by Artist_name, t.genre_id
having t.genre_id = (select genre_id from genre where name = 'Rock')
order by track_count desc
limit 10;



/* 3. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. 
Order by the song length with the longest songs listed first. */

with cte1(avg_ms) as
	(select round(avg(t.milliseconds),2) from track t)

select tr.name Track_name, tr.milliseconds, cte1.avg_ms milli_sec
from track tr, cte1
where tr.milliseconds > cte1.avg_ms
order by tr.milliseconds desc;


/* 4. Which media type has the highest average track duration? 
Write a query to calculate the average track duration (in milliseconds)
for each media type and identify the media type with the highest average duration. 
This information can help understand the preferred media format for longer tracks 
and potentially influence inventory management decisions. */

with avg_cte(media_id, avg_track_length_ms) as
	(select t.media_type_id, avg(t.milliseconds)
	from track t
	group by t.media_type_id
	order by avg(t.milliseconds) desc)

select mt.name, round(ac.avg_track_length_ms,2) avg_track_length_ms
from avg_cte ac
join media_type mt
on ac.media_id = mt.media_type_id
order by avg_track_length_ms desc;


/* 5. The company wants to analyse the sales report to make business plans for future.
Company wants to find out which sales person is performing on top in each country.
Write a query to display the report of country, the top sales person in that country and their sales amount. */

select Country, Top_sales_person, Total_sales from
	(select i.billing_country Country, e.first_name||' '||e.last_name employee_name, sum(i.total) Total_sales,
	first_value(e.first_name||' '||e.last_name) over win_1 as Top_sales_person
	from invoice i
	join customer c on c.customer_id = i.customer_id
	join employee e on e.employee_id = c.support_rep_id
	group by i.billing_country,e.first_name, e.last_name

	window win_1 as
		(partition by i.billing_country order by i.billing_country, sum(i.total) desc)
	) as Inner_table
where employee_name = Top_sales_person;


/**************************************************************************************************************/ 


-- Question Set 3 (Advance)


/* 1. Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent. */

select c.first_name||' '||c.last_name as Full_name, ar.name artist_name, 
sum(cast(il.unit_price as double precision)) Total_Amount_Spent
from customer c join invoice i on i.customer_id = c.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album a on a.album_id = t.album_id
join artist ar on ar.artist_id = a.artist_id
group by c.first_name, artist_name, c.last_name
order by c.first_name;



/* 2. We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres. */

select Country, Genre from
	(select i.billing_country Country, g.name Genre,
	rank() over(partition by i.billing_country order by sum(i.total) desc) Genre_rank
	from invoice i
	join invoice_line il on il.invoice_id = i.invoice_id
	join track t on t.track_id = il.track_id
	join genre g on g.genre_id = t.genre_id
	group by Country, Genre) X
where Genre_rank = 1;



/* 3. Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

select country, Full_name from
	(select i.billing_country country, c.first_name||' '||c.last_name Full_name,
	rank() over(partition by i.billing_country order by sum(i.total) desc) Country_rank
	from customer c
	join invoice i on i.customer_id = c.customer_id
	group by c.first_name, c.last_name, i.billing_country
	order by country) x
where Country_rank = 1;


/* 4. Can we identify the most influential artists based on their impact on track sales? 
Write a query to analyse the relationship between the number of tracks sold and the artists 
associated with those tracks. Identify the artists who have the highest total track sales and 
determine their impact on overall sales performance. */

with sum_cte(sale) as
	(select round(cast(sum(total) as decimal), 2) from invoice),
	wf_cte(all_sale) as
	(select sum(total) over() from invoice)

select x.Artist_name, x.Total_sale_Artist_wise, round(cast(all_sale as decimal), 2) Total_sal_all_tracks,
x.Percent_cosumed_of_all_track_sales
from
	(select ar.name Artist_name, round(cast(sum(i.total) as decimal), 2) Total_sale_Artist_wise,
	round(cast((sum(i.total)/(select sale from sum_cte))*100 as decimal), 2) Percent_cosumed_of_all_track_sales
	from invoice i
	join invoice_line il on il.invoice_id = i.invoice_id
	join track t on t.track_id = il.track_id
	join album al on al.album_id = t.album_id
	join artist ar on ar.artist_id = al.artist_id
	group by Artist_name
	order by Total_sale_Artist_wise desc) x, wf_cte
LIMIT 10;


/* 5. Company is building a website where the job-level hierarchy should be shown in levels.
Write a query to display company hierarchy with the manager being on top.
The manager should have level 1 and so on. */

with recursive rec_1 as
	(select e.employee_id, e.first_name, e.last_name, e.reports_to, 1 as hierarchy_level
	 from employee e where e.employee_id = 9
	 union
	 select e.employee_id, e.first_name, e.last_name, e.reports_to, r.hierarchy_level+1
	 from rec_1 r join employee e ON r.employee_id = e.reports_to
	)
select * from rec_1
order by hierarchy_level;





