use hotel_database;

-- Create File Format

create or replace file format FF_CSV
        type='csv'
        field_optionally_enclosed_by= '"'
        skip_header= 1
        null_if= ('NULL','null', '')

create or replace stage stg_hotel_booking 
    file_format=FF_CSV


create table bronze_hotel_booking (
    booking_id	string,
    hotel_id	string,
    hotel_city	string,
    customer_id	string,
    customer_name string,
    customer_email	string,
    check_in_date string,
    check_out_date	string,
    room_type string,
    num_guests string,
    total_amount string,
    currency string,
    booking_status string
    

) ;

copy into bronze_hotel_booking from @stg_hotel_booking  
file_format =(format_name = FF_CSV )
on_error ='CONTINUE';

SELECT * FROM bronze_hotel_booking LIMIT 20;


CREATE TABLE SILVER_HOTEL_BOOKING (
    booking_id	varchar,
    hotel_id	varchar,
    hotel_city	varchar,
    customer_id	varchar,
    customer_name varchar,
    customer_email	varchar,
    check_in_date  date,
    check_out_date	date,
    room_type varchar,
    num_guests int,
    total_amount float,
    currency varchar,
    booking_status varchar

);

select customer_email from bronze_hotel_booking 
where not (customer_email like '%@%.%') or customer_email is null ;


select total_amount from bronze_hotel_booking 
where total_amount <=0;

select check_in_date , check_out_date from BRONZE_HOTEL_BOOKING 
where try_to_date(check_out_date) < try_to_date(check_in_date);

select distinct booking_status from bronze_hotel_booking;

insert into silver_hotel_booking 
select
    booking_id,
    hotel_id,
    initcap(TRIM( hotel_city)) as  hotel_city ,
    customer_id	,
    initcap(Trim(customer_name)) as customer_name,
    case
    when customer_email like '%@%.%' then lower(trim(customer_email))
    else Null 
    END as customer_email,
    try_to_date(nullIF(check_in_date,'')) as check_in_date,
    try_to_date(nullIF(check_out_date,'')) as check_out_date,
    room_type,
    num_guests,
 
    abs(try_to_number(total_amount)) as total_amount,
     currency,
     case
        when lower (booking_status) in ('confirmeed','confirmd') then 'confirmed' 
        else booking_status
    end as booking_status 
    from bronze_hotel_booking 
    where try_to_date(check_out_date) >= try_to_date(check_in_date)
    and try_to_date(check_out_date) is not null 
    and try_to_date(check_in_date) is not null;


select * from silver_hotel_booking;

create table gold_AGG_Daily_booking as 
select 
check_in_date as date,
count(*) as total_booking,
sum(total_amount) as total_revenu 
from silver_hotel_booking 
group by check_in_date 
order by date;

create table gold_AGG_HOTEL_city_sales as 
select 
hotel_city,
sum(total_amount) as total_revenue 
from silver_hotel_booking
group by hotel_city
order by total_revenue desc;

create table gold_booking_clean as 
select 
booking_id	,
    hotel_id	,
    hotel_city	,
    customer_id	,
    customer_name ,
    customer_email,
    check_in_date ,
    check_out_date,
    room_type ,
    num_guests ,
    total_amount ,
    currency ,
    booking_status 

    from silver_hotel_booking;


    select * from gold_booking_clean;
    select * from gold_agg_daily_booking;
    select * from gold_AGG_HOTEL_city_sales;

    

    



        
        