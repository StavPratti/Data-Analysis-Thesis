 --Creation of database

 --Creation of tables through: right-click database name > tasks > import flat file > ...
 --you should fine the data types and constraints below


 --drop unused columns
 alter table [aegean_reviews]
 drop column reviewer_id, reviewer_name, comments;

  alter table ath_reviews
  drop column reviewer_id, reviewer_name, comments;

  alter table skg_reviews
  drop column reviewer_id, reviewer_name, comments;

  alter table creta_reviews
  drop column reviewer_id, reviewer_name, comments;

  alter table aegean_listings
  drop column scrape_id, last_scraped, source, neighborhood_overview,
  host_thumbnail_url, host_listings_count, host_has_profile_pic,
  neighbourhood, neighbourhood_group_cleansed, minimum_minimum_nights,
  maximum_minimum_nights, minimum_maximum_nights, maximum_maximum_nights,
  calendar_last_scraped, license

  alter table ath_listings
  drop column scrape_id, last_scraped, source, neighborhood_overview,
  host_thumbnail_url, host_listings_count, host_has_profile_pic,
  neighbourhood, neighbourhood_group_cleansed, minimum_minimum_nights,
  maximum_minimum_nights, minimum_maximum_nights, maximum_maximum_nights,
  calendar_last_scraped, license

  alter table skg_listings
  drop column scrape_id, last_scraped, source, neighborhood_overview,
  host_thumbnail_url, host_listings_count, host_has_profile_pic,
  neighbourhood, neighbourhood_group_cleansed, minimum_minimum_nights,
  maximum_minimum_nights, minimum_maximum_nights, maximum_maximum_nights,
  calendar_last_scraped, license


  alter table creta_listings
  drop column scrape_id, last_scraped, source, neighborhood_overview,
  host_thumbnail_url, host_listings_count, host_has_profile_pic,
  neighbourhood, neighbourhood_group_cleansed, minimum_minimum_nights,
  maximum_minimum_nights, minimum_maximum_nights, maximum_maximum_nights,
  calendar_last_scraped, license  
  
  --execute one by one
  sp_rename 'aegean_listings.id', 'listing_id', 'COLUMN';
  sp_rename 'aegean_reviews.id', 'review_id', 'COLUMN';
  sp_rename 'aegean_reviews.date', 'review_date', 'COLUMN';

  sp_rename 'ath_listings.id', 'listing_id', 'COLUMN';
  sp_rename 'ath_reviews.id', 'review_id', 'COLUMN';
  sp_rename 'ath_reviews.date', 'review_date', 'COLUMN';

  sp_rename 'creta_listings.id', 'listing_id', 'COLUMN';
  sp_rename 'creta_reviews.id', 'review_id', 'COLUMN';
  sp_rename 'creta_reviews.date', 'review_date', 'COLUMN';

  sp_rename 'skg_listings.id', 'listing_id', 'COLUMN';
  sp_rename 'skg_reviews.id', 'review_id', 'COLUMN';
  sp_rename 'skg_reviews.date', 'review_date', 'COLUMN';


--union the similar tables to one!

--CALENDAR
select *
into airbnb_calendar
from aegean_calendar
UNION ALL
select *
from ath_calendar
UNION ALL
select *
from skg_calendar
UNION ALL
select * 
from creta_calendar

--REVIEWS
select *
into airbnb_reviews
from aegean_reviews
UNION ALL
select *
from ath_reviews
UNION ALL
select *
from skg_reviews
UNION ALL
select * 
from creta_reviews

--LISTINGS

select *
into airbnb_listings
from aegean_listings
UNION ALL
select *
from ath_listings
UNION ALL
select *
from skg_listings
UNION ALL
select * 
from creta_listings

--in reality, we did what we need to do and we can DROP actually the source tables now that we have the final ones.
--however we are not goint to do this as long as we might need something else to do more.

--in order to understand if there are duplicate values as far as the keys is concerned (listing_id, review_id for reviews and listings table), we are going to write the following query

SELECT count(distinct listing_id), count(*)
  FROM [Airbnb Listings Greece].[dbo].[airbnb_listings]

  SELECT count(distinct review_id), count(*)
  FROM [Airbnb Listings Greece].[dbo].[airbnb_reviews]

  --4 194 300 rows
  SELECT count(*)
  FROM [Airbnb Listings Greece].[dbo].[airbnb_calendar]

  --4 194 300 rows. That means that for each listing and date we have exactly one unique record!
  SELECT count(1)
  FROM [Airbnb Listings Greece].[dbo].[airbnb_calendar]
  group by listing_id, date

  
  --Data Warehouse
  --check column by column to see if there is any null value to replace it accordingly

  SELECT review_id, ISNULL(listing_id, 0) AS listing_id, review_date
  INTO FactReviews
  FROM airbnb_reviews

  --check column by column to see if there is any null value to replace it accordingly
  SELECT ISNULL(listing_id, 0) as listing_id, ISNULL(date, '1900-01-01') as date, 
  case 
	when available = 'f' then 0 else 1
	end as available, ISNULL(price, 0) as price, ISNULL(adjusted_price, 0) as adjusted_price, 
	ISNULL(minimum_nights, 0) as calendar_minimum_nights,
  ISNULL(maximum_nights, 0) as calendar_maximum_nights
  INTO FactCalendar
  FROM airbnb_calendar

  --check column by column to see if the data type can be enhanced/improved with "lighter" data type
  --in terms of size

  --as long as is 1/0 then it can be bit
  ALTER TABLE FactCalendar
  ALTER COLUMN available bit;


  SELECT DISTINCT host_id, host_url, ISNULL(host_name, 'Unknown') as host_name, 
  ISNULL(host_since, '1900-01-01') as host_since, ISNULL(host_location, 'Unknown') as host_location,
  host_about, ISNULL(host_response_time, 'N/A') as host_response_time,
  isnull(replace(replace(host_response_rate, '%',''),'N/A', '-1'), '-1') as host_response_rate,
   isnull(replace(replace(host_acceptance_rate, '%',''),'N/A', '-1'), '-1') as host_acceptance_rate,
   ISNULL(host_is_superhost, -1) as host_is_superhost, host_picture_url,
   host_total_listings_count,  replace(host_verifications, '[]', 'None') as host_verifications,
   ISNULL(host_identity_verified, -1) as host_identity_verified
   INTO DimHost
   FROM airbnb_listings

--check column by column to see if there is any null value to replace it accordingly
  select distinct host_identity_verified
  from airbnb_listings

  ALTER TABLE DimHost
  ALTER COLUMN host_response_rate smallint;

  ALTER TABLE DimHost
  ALTER COLUMN host_acceptance_rate smallint;


  -----------------------------------
  CREATE TABLE DimLocation (
  location_id int identity(1,1) primary key,
  neighbourhood_description nvarchar(150)
  )
  
  INSERT INTO DimLocation
  SELECT DISTINCT neighbourhood_cleansed
  FROM airbnb_listings

  SET IDENTITY_INSERT DimLocation ON
  
  INSERT INTO DimLocation (location_id,neighbourhood_description )
  SELECT 0, 'Unknown'
  
  SET IDENTITY_INSERT DimLocation OFF

  -------------------

  CREATE TABLE DimPropertyType (
  property_type_id int identity(1,1) primary key,
  property_type_description nvarchar(50)
  )
  
  INSERT INTO DimPropertyType
  SELECT DISTINCT property_type
  FROM airbnb_listings

  SET IDENTITY_INSERT DimPropertyType ON
  
  INSERT INTO DimPropertyType (property_type_id,property_type_description )
  SELECT 0, 'Unknown'
  
  SET IDENTITY_INSERT DimPropertyType OFF


  ------------
  CREATE TABLE DimRoomType (
  room_type_id int identity(1,1)  primary key,
  room_type_description nvarchar(50)
  )
  
  INSERT INTO DimRoomType
  SELECT DISTINCT room_type
  FROM airbnb_listings

  SET IDENTITY_INSERT DimRoomType ON
  
  INSERT INTO DimRoomType (room_type_id, room_type_description )
  SELECT 0, 'Unknown'
  
  SET IDENTITY_INSERT DimRoomType OFF


  ------------------

  SELECT listing_id, isnull(host_id, 0) as host_id, isnull(location_id, 0) as location_id,
   isnull(property_type_id, 0) as property_type_id, isnull(room_type_id, 0) as room_type_id, 
   listing_url, name, description, picture_url, isnull(price, 0) as price, latitude, longitude, 
   accommodates, bathrooms,
   isnull(bathrooms_text, '-1 baths') as bathrooms_text, ISNULL(bedrooms, 0) AS bedrooms, 
   ISNULL(beds, 0) as beds, amenities, minimum_nights, maximum_nights, minimum_nights_avg_ntm,
   maximum_nights_avg_ntm, has_availability, availability_30, availability_60, availability_90,
   availability_365, instant_bookable, number_of_reviews, number_of_reviews_ltm, number_of_reviews_l30d,
   isnull(first_review, '1900-01-01') as first_review,isnull(last_review, '1900-01-01') as last_review,
   reviews_per_month, review_scores_rating, review_scores_accuracy, review_scores_cleanliness,
   review_scores_checkin, review_scores_communication, review_scores_location, review_scores_value,
   calculated_host_listings_count, calculated_host_listings_count_entire_homes, 
   calculated_host_listings_count_private_rooms,
   calculated_host_listings_count_shared_rooms
   INTO FactListings
   FROM airbnb_listings a
    left join DimLocation c on a.neighbourhood_cleansed = c.neighbourhood_description
    left join DimPropertyType d on a.property_type = d.property_type_description
    left join DimRoomType e on a.room_type = e.room_type_description


   SELECT COUNT(1)
   FROM airbnb_listings