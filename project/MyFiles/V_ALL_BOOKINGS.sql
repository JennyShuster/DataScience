USE [NoShow]
GO

/****** Object:  View [dbo].[V_ALL_BOOKINGS]    Script Date: 28/03/2020 17:00:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[V_ALL_BOOKINGS] AS


  ----[FutureBookings]-NOT CANCELLED----
  WITH A AS
  (
  SELECT [Date_CD]
	  ,[Date]
	  ,YEAR([Date]) AS [Year]
	  ,MONTH([Date]) AS [Month]
	  ,DAY([Date]) AS [Day]
	  ,DATEPART(WEEKDAY,[Date]) AS [WeekDay]
	  ,[Code]
      ,[Staff]
      ,[Service]
	  ,0 AS [IsCanceled]
	  ,NULL AS [CancelDay]
	  ,NULL AS [CancelWeekday]
	  ,NULL AS [CanceledBy]
	  ,NULL AS [Days]
  FROM [NoShow].[dbo].[FutureBookings]),

  B AS 

  (SELECT DISTINCT 
       CAST([Date_CD] AS CHAR(8)) + [Code] + [Staff] + [Service] + '0' AS Booking_CD
      ,[Date_CD]
  	  ,[Date]
	  ,[Year]
	  ,[Month]
	  ,[Day]
	  ,[WeekDay]
	  ,[Code]
      ,[Staff]
      ,[Service]
	  ,[IsCanceled]
	  ,[CancelDay]
	  ,[CancelWeekday]
	  ,[CanceledBy]
	  ,[Days]
  FROM A),

  ----[ClientCancellations]----

  C AS

  (SELECT
	   CAST([Date_CD] AS CHAR(8)) + [Code] + [Staff] + [Service] + '1' AS Booking_CD
      ,[Date_CD]
      ,[BookingDate] AS [Date]
	  ,YEAR([BookingDate]) AS [Year]
	  ,MONTH([BookingDate]) AS [Month]
	  ,DAY([BookingDate]) AS [Day]
	  ,DATEPART(WEEKDAY,[BookingDate]) AS [WeekDay]
      ,[Code]
      ,[Staff]
      ,[Service]
	  ,1 AS [IsCanceled]
	  ,DAY([CancelDate]) AS [CancelDay]
	  ,DATEPART(WEEKDAY, [CancelDate]) AS [CancelWeekday]
	  ,[CanceledBy]
	  ,[Days]

  FROM [NoShow].[dbo].[ClientCancellations]),


----[NoShowReport0]------

  D AS

  (SELECT
       CAST([Date_CD] AS CHAR(8)) + [Code] + [Staff] + [Service] + '0' AS Booking_CD
	  ,[Date_CD]
      ,[Date]
	  ,YEAR([Date]) AS [Year]
	  ,MONTH([Date]) AS [Month]
	  ,DAY([Date]) AS [Day]
	  ,DATEPART(WEEKDAY,[Date]) AS [WeekDay]
      ,[Code]
      ,[Staff]
      ,[Service]
	  ,1 AS [IsCanceled]
	  ,DAY([Date]) AS [CancelDay]
	  ,DATEPART(WEEKDAY,[Date]) AS [CancelWeekday]
	  ,NULL AS [CanceledBy]
	  ,0 AS [Days]

  FROM [NoShow].[dbo].[NoShowReport0])

,E AS

(SELECT * 
FROM B
UNION
SELECT *
FROM C
UNION
SELECT *
FROM D)

,F AS

(SELECT DISTINCT *
,ROW_NUMBER() OVER(PARTITION BY Booking_CD
				   ORDER BY [Date_CD]) AS rownum
FROM E)

SELECT 
  [Booking_CD]
 ,[Date_CD]
 ,[Date]
 ,[Year]
 ,[Month]
 ,[Day]
 ,[WeekDay]
 ,[Code]
 ,[Staff]
 ,[Service]
 ,[IsCanceled]
 ,[CancelDay]
 ,[CancelWeekday]
 ,[CanceledBy]
 ,[Days]
FROM F
WHERE rownum = 1




GO


