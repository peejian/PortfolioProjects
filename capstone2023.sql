
/*
The main question that I want to investigate is: 

How do annual members and casual riders use Cyclistic bikes differently?

*/

--I found that thereare inconsistencies with data types especially with start_station_id and end_station_id 
--I converted all data types to nvarchar except for start and endtimes, those were kept at datetime for obvious reasons 
-- NVARCHAR(255) was chosen as I did not plan to do any math with station IDs

ALTER TABLE dbo.['202209-divvy-publictripdata$']
ALTER COLUMN end_station_id NVARCHAR(255) --this code was applied multiple times where it was needed


----------------------------------------------------------------------------------------------------------------
--I needed to consolidate all the tables into one 
SELECT *
INTO #TempTable
FROM (
    SELECT * FROM dbo.['202304-divvy-tripdata$']
    UNION ALL 
    SELECT * FROM dbo.['202303-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202302-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202301-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202212-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202211-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202210-divvy-tripdata$']
	UNION ALL 
    SELECT* FROM dbo.['202209-divvy-publictripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202208-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202207-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202206-divvy-tripdata$']
	UNION ALL 
    SELECT * FROM dbo.['202205-divvy-tripdata$']
) AS CombinedData;

-- insert contents of temp table into a new table
SELECT *
INTO Divvy_Trips_2023
FROM #TempTable;

--drop the temp table
DROP TABLE #TempTable

----------------------------------------------------------------------------------------------------------------

-- I want to find out how both casuals and members differ by trip duration
--calculate duration and add duration as new column
ALTER TABLE Divvy_Trips_2023
ADD trip_duration INT;

-- Update the table to populate the trip_duration column
UPDATE Divvy_Trips_2023
SET trip_duration = DATEDIFF(SECOND,started_at,ended_at)

--average ride time in for 2022
SELECT AVG(trip_duration) FROM Divvy_Trips_2023

-- average ride time by member_casual
SELECT AVG(trip_duration) AS averageRideTime, member_casual
FROM Divvy_Trips_2023
GROUP BY member_casual

--average ride time and no of trips by rideable type 
SELECT COUNT(ride_id) as NoOfTrips,AVG(trip_duration) as AverageRideTime, rideable_type 
FROM Divvy_Trips_2023
GROUP BY rideable_type

--average ride time and no of trips by member_casual
SELECT COUNT(ride_id) as NoOfTrips,AVG(trip_duration) as AverageRideTime, member_casual 
FROM Divvy_Trips_2023
GROUP BY member_casual

--Longest ride 
SELECT *
FROM Divvy_Trips_2023
WHERE trip_duration = (
  SELECT MAX(trip_duration)
  FROM Divvy_Trips_2023
);

-- shortest ride ( more than 5 sec)
SELECT *
FROM Divvy_Trips_2023
WHERE trip_duration = (
  SELECT MIN(trip_duration)
  FROM Divvy_Trips_2023
  WHERE trip_duration > 60
);

-- it appears that there are some instances where the trip duration returns a negative value
-- I attempt to see how many

SELECT * FROM Divvy_Trips_2023
WHERE trip_duration < 0

--Only 11 rows
--I can choose to drop the row OR, assuming the start_time and end_time have been switched, just turn them into a positive int.

--for fixing 

UPDATE Divvy_Trips_2023
SET trip_duration = trip_duration * -1
WHERE trip_duration < 0

-- dropping rows 

DELETE FROM Divvy_Trips_2023
WHERE trip_duration < 0;


--now it should show the true shortest ride
SELECT MIN(trip_duration) FROM Divvy_Trips_2023

--checking to see if ride ID is unique ; tldr, yes
SELECT COUNT(DISTINCT(ride_id)), COUNT(ride_id) FROM Divvy_Trips_2023

----------------------------------------------------------------------------------------------------------------------

--I run some basic stats for trip duration 
--mode of duration
SELECT top 1 trip_duration, COUNT(trip_duration) AS frequency
FROM Divvy_Trips_2023
GROUP BY trip_duration
ORDER BY frequency DESC

--median duration (540)
WITH ranked_data AS (
  SELECT trip_duration, ROW_NUMBER() OVER (ORDER BY trip_duration) AS row_num,
         COUNT(*) OVER () AS total_rows
  FROM Divvy_Trips_2023
)
SELECT trip_duration
FROM ranked_data
WHERE row_num IN ((total_rows + 1) / 2, (total_rows + 2) / 2);

--find average trip duration and number of rides by month and member type
SELECT MONTH(started_at) AS Month, AVG(trip_duration) AS AverageDuration, COUNT(trip_duration) AS noOfRides, member_casual
FROM Divvy_Trips_2023
GROUP BY MONTH(started_at), member_casual
ORDER BY MONTH(started_at) DESC;

-- average ride, no of rides by days of the week 
SELECT DATEPART(WEEKDAY,started_at) AS DayOfWeek, AVG(trip_duration) AS AverageDuration, COUNT(*) AS noOfRides, member_casual
FROM Divvy_Trips_2023
GROUP BY DATEPART(WEEKDAY, started_at), member_casual
ORDER BY DATEPART(WEEKDAY, started_at);


-- average ride, no of rides by days of the week and quarter
SELECT DATEPART(WEEKDAY, started_at) AS DayOfWeek,
       DATEPART(QUARTER, started_at) AS Quarter,
       AVG(trip_duration) AS AverageDuration,
       COUNT(*) AS noOfRides,
	   member_casual
FROM Divvy_Trips_2023
GROUP BY DATEPART(WEEKDAY, started_at), DATEPART(QUARTER, started_at), member_casual
ORDER BY DATEPART(QUARTER, started_at),DATEPART(WEEKDAY, started_at);

--number of rides by member_casual
SELECT COUNT(*)AS noOfRides, SUM(trip_duration)/10000 AS duration, member_casual FROM Divvy_Trips_2023
GROUP BY member_casual

--no of rides by rideable_type
SELECT rideable_type,
       SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casual_count,
       SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS member_count
FROM Divvy_Trips_2023
GROUP BY rideable_type;


-- no of rides by rideable type by month
SELECT MONTH(started_at) AS Month, rideable_type,
       SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casual_count,
       SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS member_count
FROM Divvy_Trips_2023
GROUP BY MONTH(started_at), rideable_type
ORDER BY Month ASC;

--trying out the same thing while using a CTE
WITH trip_counts AS (
    SELECT MONTH(started_at) AS Month, rideable_type,
           SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casual_count,
           SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS member_count
    FROM Divvy_Trips_2023
    GROUP BY MONTH(started_at), rideable_type
)
SELECT Month, rideable_type, casual_count, member_count
FROM trip_counts
ORDER BY Month ASC;


SELECT MONTH(started_at) as mth, AVG(trip_duration) AS averageTripDuration,rideable_type,member_casual
FROM Divvy_Trips_2023
GROUP BY MONTH(started_at),rideable_type, member_casual
ORDER BY MONTH(started_at)

SELECT TOP 5 MAX(trip_duration), rideable_type
FROM Divvy_Trips_2023
GROUP by rideable_type
ORDER BY MAX(trip_duration)

SELECT rideable_type, trip_duration
FROM (
    SELECT rideable_type, trip_duration,
           ROW_NUMBER() OVER (PARTITION BY rideable_type ORDER BY trip_duration DESC) AS rn
    FROM Divvy_Trips_2023
) AS sub
WHERE rn <= 25;

--find average ride count by station, by month 

WITH ride_counts AS (
    SELECT
        MONTH(started_at) AS date,
        start_station_name,
        COUNT(*) AS ride_count
    FROM
        Divvy_Trips_2023
    GROUP BY
        start_station_name,
        MONTH(started_at)
)
SELECT
    date,
    ride_count/SUM(ride_count) AS AvgRideCount
	FROM ride_counts
	WHERE date = 1
	group by date, ride_count

SELECT MONTH(started_at) as mth, start_station_name, COUNT(*) AS ride_count 
FROM Divvy_Trips_2023
GROUP BY start_station_name, MONTH(started_at)
ORDER BY MONTH(started_at), ride_count DESC



SELECT end_station_name, COUNT(*) AS ride_count 
FROM Divvy_Trips_2023
GROUP BY end_station_name
ORDER BY ride_count DESC
