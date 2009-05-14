-- tel aantal ticks er zijn van een bepaalde fleet 4 weken voor departure
select count(*) from sales_ticks t, sales_legs l 
	where t.sales_leg_id = l.id and t.capacity = 97 and (l.date - t.date) = 28;
	
-- count unique legs waar bookings ooit gelimiteerd waren
select count(distinct(sales_leg_id)) from sales_ticks where seats_sold >= (capacity*0.95);

-- selecteer sales_ticks van een bepaalde leg, op een gegeven tijdsmoment
select avg(seats_sold),stddev(seats_sold),min(seats_sold),max(seats_sold)
	from sales_ticks t, sales_legs l 
	where t.sales_leg_id = l.id and (l.date - t.date) = 120;
	
-- toon alle flight legs die niet vanuit Zaventem vertrekken én niet in Zaventem aankomen
-- de airport_id van BRU is 154
select * from flight_leg_groups where departure_airport_id != 154 and arrival_airport_id != 154
	
-- help from http://www.varlena.com/GeneralBits/Tidbits/bernier/art_66/graphingWithR.html
-- Functie voor lijn grafieken met "R"
CREATE OR REPLACE FUNCTION r_line(title text,sql text) RETURNS text AS 
$BODY$
str <- pg.spi.exec (sql);
pdf('/tmp/line_plot.pdf');
plot(str,type="l",main=title,col="red",ylim=c(0,100));
dev.off();
print('done');
$BODY$
LANGUAGE 'plr' VOLATILE;

-- Functie voor scatter grafieken en regressielijn met "R"
CREATE OR REPLACE FUNCTION r_scatter(title text, sql text)
  RETURNS text AS
$BODY$
data <- pg.spi.exec (sql);
pdf('/tmp/scatter_plot.pdf');
plot(data,main=title,cex=0.3, 
	pch=20,col=rgb(255,0,0,2,maxColorValue=255),ylim=c(0,100));
regressie <- lm(data);
abline(regressie);
dev.off();
print('done');
$BODY$
  LANGUAGE 'plr' VOLATILE;

-- Functie voor histogrammen met "R"
CREATE OR REPLACE FUNCTION r_histogram(title text, sql text) 
	RETURNS text AS 
$BODY$
str <- pg.spi.exec(sql);
pdf('/tmp/myhist.pdf');
hist(str,main=title);
dev.off();
print('done');
$BODY$
	LANGUAGE 'plr' VOLATILE;

-- Voorbeeld: line graph die de gemiddelde verkoop weergeeft voor AVRO
SELECT r_line('Sales progress for RJ85','select (t.date - l.date) as "Dagen voor vertrek", avg(seats_sold) AS "Verkochte zetels"
	from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.capacity = 82 group by (t.date - l.date) order by (t.date - l.date)')

-- Or a scatter
SELECT r_scatter('Sales progress for RJ85','select (t.date - l.date) as "Dagen voor vertrek", seats_sold AS "Verkochte zetels"
	from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.capacity = 82 order by (t.date - l.date)')

-- hexbin
SELECT r_hexbin('Sales progress for RJ85','select (t.date - l.date) as "Dagen voor vertrek", seats_sold AS "Verkochte zetels"
	from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.capacity = 82 order by (t.date - l.date)')
	
-- alle ids van vluchten die ooit gelimiteerd waren
SELECT distinct(l.id) from sales_ticks t, sales_legs l 
	where t.sales_leg_id = l.id and t.capacity = 82 and t.seats_sold >= 80
	
	
-- Count all leg_ids die slechte cap hebben op -28d
select count(distinct(l.id))
	from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold <= t.capacity*0.10 and (l.date - t.date) = 28
	
-- Alle leg ids die ooit gecapped waren
select count(distinct(l.id))
	from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold >= t.capacity*0.90

-- Filter voor slechte leg_ids
select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold <= t.capacity*0.10 and (l.date - t.date) = 28
	UNION select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold >= t.capacity*0.90
	
CREATE OR REPLACE FUNCTION filter_leg_ids(min_cap float, days_to_go integer, max_cap float) RETURNS setof integer AS 
$$
select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold <= t.capacity*$1 and (l.date - t.date) = $2
	UNION select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold >= t.capacity*$3
$$ 
LANGUAGE SQL STABLE;
	
-- Functie voor het selecteren van het aantal verkochte seats op specifieg moment
select t.seats_sold from sales_ticks t, sales_legs l where t.sales_leg_id = LEG_ID and (l.date - t.date) = DAYS_TO_GO

CREATE OR REPLACE FUNCTION seats_sold(leg_id integer, days_to_go integer) RETURNS integer AS 
$$
select t.seats_sold from sales_ticks t, sales_legs l where t.sales_leg_id = $1 and l.id = $1 and (l.date - t.date) = $2
$$ 
LANGUAGE SQL IMMUTABLE;

-- big query voor het tonen van de -28d, -0d en de factor van de gefilterde rijen
select id,seats_sold(id,28) AS "28D", seats_sold(id,0) AS "0D",  seats_sold(id,0)/seats_sold(id,28)  as "Factor" from sales_legs where id not in (select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold <= t.capacity*0.10 and (l.date - t.date) = 28
	UNION select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold >= t.capacity*0.90)
	
-- alternatieve versie van vorige
select l.id,seats_sold(l.id,0)/CAST(t.seats_sold as float) from sales_legs l, sales_ticks t 
	where l.id = t.sales_leg_id and t.date = l.date - 28 and t.seats_sold > 0

-- met filers
select (seats_sold(l.id,0)/CAST(t.seats_sold as float)) as "x" from sales_legs l, sales_ticks t where l.id = t.sales_leg_id and t.date = l.date - 28 and t.seats_sold > 0 and l.id not in (select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold <= t.capacity*0.10 and (l.date - t.date) = 28
	UNION select l.id from sales_ticks t, sales_legs l where t.sales_leg_id = l.id and t.seats_sold >= t.capacity*0.90) order by "x"
	
-- haal de distributie op voor verkoop_28 onder de 20
select seats_sold(l.id,0) as "0d",count(*) from sales_legs l, sales_ticks t 
	where l.id = t.sales_leg_id and t.date = l.date - 28 and t.seats_sold <= 20 group by "0d" order by "0d"