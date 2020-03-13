USE [NoShow]
GO

/****** Object:  View [dbo].[V_ff]    Script Date: 11/03/2020 8:47:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Script for SelectTopNRows command from SSMS  ******/
ALTER VIEW [dbo].[V_ff] AS

WITH A AS

(SELECT 
	    Client
	   ,[Date_CD]
	   ,[Staff]
	   ,SUM([Amount]) OVER (PARTITION BY Client, [Date_CD]) AS [TAmount]
	   ,SUM([GST]) OVER (PARTITION BY Client, [Date_CD]) AS [TGST]
	   ,SUM([PST]) OVER (PARTITION BY Client, [Date_CD]) AS [TPST]
	   ,LOWER([Description]) AS LDesc
	   ,ROW_NUMBER () OVER(PARTITION BY Client, [Date_CD]
						   ORDER BY [Date_CD]) AS rownum
FROM [NoShow].[dbo].[ReceiptTransactions]
)

,B1 AS

(SELECT Client
	   ,[Date_CD]
	   ,[TAmount]
	   ,[TGST]
	   ,[TPST]
	   ,[Staff]
	   ,LDesc
FROM A
WHERE rownum = 1),

B2 AS	   

(
SELECT DISTINCT Client
	   ,[Date_CD]
	   ,1 AS [IsProdPerch]
	   ,[TAmount]
	   ,[TGST]
	   ,[TPST]
	   ,[Staff]
	   ,LDesc   
FROM A
WHERE LDesc IN (SELECT DISTINCT LOWER([Description]) FROM [NoShow].[dbo].[ProductListing])
AND rownum = 1),

C AS

(
SELECT DISTINCT B1.Client
	   ,B1.[Date_CD]
	   ,ISNULL(B2.[IsProdPerch],0) AS [IsProdPerch]
	   ,MAX(B1.[Date_CD]) OVER(PARTITION BY B1.Client
						ORDER BY B1.Client, B1.[Date_CD]
						ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS [LastDate_CD]
	   ,B1.[TAmount]
	   ,B1.[TGST]
	   ,B1.[TPST]
	   ,B1.[Staff]
	   ,B1.[LDesc]   
FROM B1
LEFT JOIN B2 ON B1.Client=B2.Client AND B1.[Date_CD]=B2.[Date_CD] AND B1.[TAmount]=B2.[TAmount] 
AND B1.[TGST]=B2.[TGST] AND B1.[TPST]=B2.[TPST] AND B1.[Staff]=B2.[Staff] AND B1.[LDesc]=B2.[LDesc]),

D AS

(
SELECT  Curr.Client
	   ,Curr.Date_CD
	   ,Past.[Staff] AS RTLastStaff
	   ,Past.[LDesc] AS RTLastLDesc
	   ,Past.[TAmount] AS LastTotalAmount
       ,SUM(Past.[TGST]) OVER (PARTITION BY Past.Client
								 ORDER BY Past.Client, Past.[Date_CD] DESC
								 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS LastTotalGST
       ,SUM(Past.[TPST]) OVER (PARTITION BY Past.Client
								 ORDER BY Past.Client, Past.[Date_CD] DESC
								 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS LastTotalPST
       ,[LastWasPerch] = Past.IsProdPerch
FROM C Curr
LEFT JOIN C Past ON Curr.[LastDate_CD] = Past.Date_CD AND Curr.Client = Past.Client),

E AS 

(SELECT DISTINCT 
       [Booking_CD]
	  ,[Date_CD]
	  ,[Date]
      ,[Year]
      ,[Season] = CASE WHEN [Month] IN (12,1,2) THEN 'Winter'
					 WHEN [Month] IN (3,4,5) THEN 'Spring'
					 WHEN [Month] IN (6,7,8) THEN 'Summer'
					 WHEN [Month] IN (9,10,11) THEN 'Fall'
					 END
      ,[WeekEnd] = CASE WHEN [WeekDay] IN (6,7,1) THEN 1
						WHEN [WeekDay] IN (2,3,4,5) THEN 0
						END
	  ,MAX([Date_CD]) OVER(PARTITION BY [Code]
								  ORDER BY [Code], [Date_CD]
								  ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS LastDate_CD
	  ,MAX([Date]) OVER(PARTITION BY [Code]
								  ORDER BY [Code], [Date_CD]
								  ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS LastDate
      ,[Code]
      ,[Staff]
      ,[Service]
      ,[IsCanceled]
      ,[CancelDay]
      ,[CancelWeekday]
      ,[CanceledBy]
      ,[Days]
  FROM [NoShow].[dbo].[V_ALL_BOOKINGS])

,F AS

(SELECT Curr.*

	  ,Past.[Year] AS LastYear
	  ,Past.[Season] AS LastSeason
	  ,Past.[WeekEnd] AS LastWeekEnd
	  ,Past.[Staff] AS BLastStaff
	  ,Past.[Service] AS BLastService
	  ,Past.[IsCanceled] AS LastIsCanceled
	  ,Past.[CanceledBy] AS LastCanceledBy
	  ,Past.[CancelWeekday] AS LastCancelWeekday
	  ,COUNT(Past.[Booking_CD]) OVER (PARTITION BY Past.[Code]
						         ORDER BY Past.[Code], Past.[Date_CD], Past.[Booking_CD]
						         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalClientBookingsTillNow
	  ,SUM(Past.[IsCanceled]) OVER (PARTITION BY Past.[Code]
							ORDER BY Past.[Code], Past.[Date_CD], Past.[Booking_CD]
							ROWS BETWEEN UNBOUNDED PRECEDING  AND CURRENT ROW) AS TotalClientCancellationsTillNow
	  ,COUNT(Past.[Booking_CD]) OVER (PARTITION BY Past.[Staff]
						         ORDER BY Past.[Staff], Past.[Date_CD], Past.[Booking_CD]
						         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalStaffBookingsTillNow
	  ,SUM(Past.[IsCanceled]) OVER (PARTITION BY Past.[Staff]
							ORDER BY Past.[Staff], Past.[Date_CD], Past.[Booking_CD]
							ROWS BETWEEN UNBOUNDED PRECEDING  AND CURRENT ROW) AS TotalStaffCancellationsTillNow
	  ,COUNT(Past.[Booking_CD]) OVER (PARTITION BY Past.[Service]
						         ORDER BY Past.[Service], Past.[Date_CD], Past.[Booking_CD]
						         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS TotalServiceBookingsTillNow
	  ,SUM(Past.[IsCanceled]) OVER (PARTITION BY Past.[Service]
							ORDER BY Past.[Service], Past.[Date_CD], Past.[Booking_CD]
							ROWS BETWEEN UNBOUNDED PRECEDING  AND CURRENT ROW) AS TotalServiceCancellationsTillNow
FROM E Curr
LEFT JOIN E Past ON Curr.LastDate_CD = Past.Date_CD AND Curr.[Code] = Past.[Code]),
		  
G AS (

SELECT 
---Time of booking
	   F.[Date_CD]
      ,F.[Year]
      ,F.[Season]
      ,F.[WeekEnd]
	  ,F.LastYear
	  ,F.LastSeason
	  ,F.LastWeekEnd
	  ,F.[Date]
	  ,F.[LastDate]
	  ,DaysRecency = DATEDIFF(DD, F.[LastDate],F.[Date])
---Client
      ,F.[Code] AS [ClientCode]
---Staff
      ,F.[Staff]
	  ,F.BLastStaff
	  ,D.RTLastStaff
---Service
	  ,F.BLastService AS [BLastServiceCode]
	  ,[BLastWomenMenService]  = CASE WHEN LOWER(SL2.[Desc]) LIKE '%women%' THEN 'Woman'
								 WHEN LOWER(SL2.[Desc]) LIKE '%men%' THEN 'Man'
								 WHEN LOWER(SL2.[Desc]) LIKE '%children%' THEN 'Child'
								 WHEN LOWER(SL2.[Desc]) IS NULL THEN NULL
								 ELSE 'Other'
								 END
	  ,[BLastColorCutService]  = CASE WHEN LOWER(SL2.[Desc]) LIKE '%color%' THEN 'Color'
								 WHEN LOWER(SL2.[Desc]) LIKE '%cut%' THEN 'Cut'
								 WHEN LOWER(SL2.[Desc]) IS NULL THEN NULL
								 ELSE 'Other'
								 END
	  ,SL2.[Cate] AS [LastServiceCategory]
	  ,SL2.[Price] AS [LastServicePrice]
	  ,SL2.[Cost] AS [LastServiceCost]
	  ,F.[Service] AS [ServiceCode]
	  ,[WomenMenService]  = CASE WHEN LOWER(SL.[Desc]) LIKE '%women%' THEN 'Woman'
								 WHEN LOWER(SL.[Desc]) LIKE '%men%' THEN 'Man'
								 WHEN LOWER(SL.[Desc]) LIKE '%children%' THEN 'Child'
								 WHEN LOWER(SL.[Desc]) IS NULL THEN NULL
								 ELSE 'Other'
								 END
	  ,[ColorCutService]  = CASE WHEN LOWER(SL.[Desc]) LIKE '%color%' THEN 'Color'
								 WHEN LOWER(SL.[Desc]) LIKE '%cut%' THEN 'Cut'
								 WHEN LOWER(SL.[Desc]) IS NULL THEN NULL
								 ELSE 'Other'
								 END
	  ,SL.[Cate] AS [ServiceCategory]
	  ,SL.[Price] AS [ServicePrice]
	  ,SL.[Cost] AS [ServiceCost]
---Receipt
	  ,[RTLastWomenMen]  = CASE WHEN LOWER(D.RTLastLDesc) LIKE '%women%' THEN 'Woman'
								 WHEN LOWER(D.RTLastLDesc) LIKE '%men%' THEN 'Man'
								 WHEN LOWER(D.RTLastLDesc) LIKE '%children%' THEN 'Child'
								 WHEN LOWER(D.RTLastLDesc) IS NULL THEN NULL
								 ELSE 'Other'
								 END
	  ,[RTLastColorCutReciept]  = CASE WHEN LOWER(D.RTLastLDesc) LIKE '%color%' THEN 'Color'
								 WHEN LOWER(D.RTLastLDesc) LIKE '%cut%' THEN 'Cut'
								 WHEN LOWER(D.RTLastLDesc) IS NULL THEN NULL
								 ELSE 'Other'
								 END
 	  ,D.LastTotalAmount
	  ,D.LastTotalGST
	  ,D.LastTotalPST
	  ,[WasProdPerch] = D.[LastWasPerch]

---Cancellation
      ,F.[IsCanceled]
      ,F.[CancelDay]
      ,F.[CancelWeekday]
      ,F.[CanceledBy]
      ,F.[Days]
	  ,F.LastIsCanceled
	  ,F.LastCanceledBy
	  ,F.LastCancelWeekday
	  ,F.TotalClientCancellationsTillNow
	  ,F.TotalClientBookingsTillNow
	  ,F.TotalStaffCancellationsTillNow
	  ,F.TotalStaffBookingsTillNow
	  ,F.TotalServiceCancellationsTillNow
	  ,F.TotalServiceBookingsTillNow
	  ,CancellationPcnt = CAST(F.TotalClientCancellationsTillNow AS FLOAT) / IIF(F.TotalClientBookingsTillNow=0 OR F.TotalClientBookingsTillNow IS NULL, -1, CAST(F.TotalClientBookingsTillNow AS FLOAT))
  FROM F
  LEFT JOIN [NoShow].[dbo].[ServiceListing] SL ON F.[Service] = SL.[Code]
  LEFT JOIN [NoShow].[dbo].[ServiceListing] SL2 ON F.[BLastService] = SL2.[Code]  
  LEFT JOIN D ON F.[Date_CD] = D.[Date_CD] AND F.[Code] = D.[Client]

),

H1 AS

(
SELECT MAX(TotalClientCancellationsTillNow) AS MaxCanc
FROM G
),

H2 AS

(
SELECT MAX(TotalStaffCancellationsTillNow) AS MaxCanc
FROM G
),

H3 AS

(
SELECT MAX(TotalServiceCancellationsTillNow) AS MaxCanc
FROM G
),

I1 AS

(
SELECT ClientCode AS HighCancClient
FROM G
WHERE CAST(TotalClientCancellationsTillNow AS FLOAT) >=  (SELECT 0.15 * CAST(MaxCanc AS FLOAT) AS Con
                                                          FROM H1)
AND CancellationPcnt >= 0.7
GROUP BY ClientCode
),

I2 AS

(
SELECT ClientCode AS LowCancClient
FROM G
WHERE CAST(TotalClientCancellationsTillNow AS FLOAT) <  (SELECT 0.15 * CAST(MaxCanc AS FLOAT) AS Con
                                                          FROM H1)
AND CancellationPcnt < 0.3
GROUP BY ClientCode
),

I3 AS

(
SELECT ClientCode AS MediumCancClient
FROM G
WHERE TotalClientBookingsTillNow IS NOT NULL
AND ClientCode NOT IN (SELECT HighCancClient FROM I1)
AND ClientCode NOT IN (SELECT LowCancClient FROM I2)
GROUP BY ClientCode
),

I4 AS

(
SELECT Staff AS HighCancStaff
FROM G
WHERE CAST(TotalStaffCancellationsTillNow AS FLOAT) >=  (SELECT 0.15 * CAST(MaxCanc AS FLOAT) AS Con
                                                          FROM H2)
AND CancellationPcnt >= 0.7
GROUP BY Staff
),

I5 AS

(
SELECT Staff AS LowCancStaff
FROM G
WHERE CAST(TotalStaffCancellationsTillNow AS FLOAT) <  (SELECT 0.15 * CAST(MaxCanc AS FLOAT) AS Con
                                                          FROM H2)
AND CancellationPcnt < 0.3
GROUP BY Staff
),

I6 AS

(
SELECT Staff AS MediumCancStaff
FROM G
WHERE TotalStaffBookingsTillNow IS NOT NULL
AND Staff NOT IN (SELECT HighCancStaff FROM I4)
AND Staff NOT IN (SELECT LowCancStaff FROM I5)
GROUP BY Staff
),

I7 AS

(
SELECT ServiceCode AS HighCancService
FROM G
WHERE CAST(TotalServiceCancellationsTillNow AS FLOAT) >=  (SELECT 0.15 * CAST(MaxCanc AS FLOAT) AS Con
                                                          FROM H3)
AND CancellationPcnt >= 0.7
GROUP BY ServiceCode
),

I8 AS

(
SELECT ServiceCode AS LowCancService
FROM G
WHERE CAST(TotalServiceCancellationsTillNow AS FLOAT) <  (SELECT 0.15 * CAST(MaxCanc AS FLOAT) AS Con
                                                          FROM H3)
AND CancellationPcnt < 0.3
GROUP BY ServiceCode
),

I9 AS

(
SELECT ServiceCode AS MediumCancService
FROM G
WHERE TotalServiceBookingsTillNow IS NOT NULL
AND ServiceCode NOT IN (SELECT HighCancService FROM I7)
AND ServiceCode NOT IN (SELECT LowCancService FROM I8)
GROUP BY ServiceCode
)

SELECT 
---Time of booking
	   [Date_CD]
      ,[Year]
      ,[Season]
      ,[WeekEnd]
	  ,LastYear
	  ,LastSeason
	  ,LastWeekEnd
	  ,[Date]
	  ,[LastDate]
	  ,DaysRecency
---Client
      ,[ClientType] = CASE WHEN ClientCode IN (SELECT HighCancClient
												FROM I1)              THEN 'HighCancClient'
					       WHEN ClientCode IN (SELECT LowCancClient
												FROM I2)              THEN 'LowCancClient'
					       WHEN ClientCode IN (SELECT MediumCancClient
												FROM I3)              THEN 'MediumCancClient'
						   ELSE 'NewClient'
						   END
---Staff
      ,[Staff]
	  ,BLastStaff
	  ,RTLastStaff
	  ,[StaffCancType] = CASE WHEN Staff IN (SELECT HighCancStaff
												FROM I4)              THEN 'HighCancStaff'
					          WHEN Staff IN (SELECT LowCancStaff
												FROM I5)              THEN 'LowCancStaff'
					          WHEN Staff IN (SELECT MediumCancStaff
												FROM I6)              THEN 'MediumCancStaff'
						   END
---Service
	  ,[BLastServiceCode]
	  ,[BLastWomenMenService]
	  ,[BLastColorCutService]
	  ,[LastServiceCategory]
	  ,[LastServicePrice]
	  ,[LastServiceCost]
	  ,[ServiceCode]
	  ,[ServiceCancType] = CASE WHEN [ServiceCode] IN (SELECT HighCancService
												FROM I7)              THEN 'HighCancService'
					            WHEN [ServiceCode] IN (SELECT LowCancService
												FROM I8)              THEN 'LowCancService'
					            WHEN [ServiceCode] IN (SELECT MediumCancService
												FROM I9)              THEN 'MediumCancService'
						        END
	  ,[WomenMenService]
	  ,[ColorCutService]
	  ,[ServiceCategory]
	  ,[ServicePrice]
	  ,[ServiceCost]
---Receipt
	  ,[RTLastWomenMen]
	  ,[RTLastColorCutReciept]
 	  ,LastTotalAmount
	  ,LastTotalGST
	  ,LastTotalPST
	  ,[WasProdPerch]

---Cancellation
      ,[IsCanceled]
      ,[CancelDay]
      ,[CancelWeekday]
      ,[CanceledBy]
      ,[Days]
	  ,LastIsCanceled
	  ,LastCanceledBy
	  ,LastCancelWeekday
	  ,TotalClientCancellationsTillNow
	  ,TotalClientBookingsTillNow
	  ,CancellationPcnt
FROM G




--GO


