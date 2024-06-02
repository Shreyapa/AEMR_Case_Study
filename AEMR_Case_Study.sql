/* PART 1. ENERGY STABILITY AND MARKET OUTAGES */

/* Q1: Count the number of valid (Approved) Outages Events in 2016 and 2017 */

SELECT COUNT(*) as Total_Number_Outages, Outage_Reason, Year
FROM AEMR_Outage_Table
WHERE Status = 'Approved'
GROUP BY Outage_Reason, Year

/* Q2: Count the total number of valid (Approved) Outages Events occured in 2016 and 2017 per month*/

SELECT Year,Month, COUNT(*) as Total_Number_Outages
FROM AEMR_Outage_Table
WHERE Status = 'Approved'
GROUP BY Year, Month
ORDER BY Year, Month, Total_Number_Outages DESC
LIMIT 10

/* Q3: The average duration in days for each approved participant and outages types in 2016 and 2017 */

SELECT Participant_Code,Outage_Reason,
	   Year,COUNT(*) as Total_Number_Outages_Events,  
	   ROUND(AVG(ABS(JULIANDAY(End_Time) - JULIANDAY(Start_Time))),2) AS Average_Outage_Duration_In_Days
FROM AEMR_Outage_Table
WHERE Status = 'Approved'
GROUP BY Participant_Code,Outage_Reason,Year
ORDER BY Total_Number_Outages_Events DESC
LIMIT 10

/* Q4: Classify each participant as either high, medium or low risk based off their approved average outage duration time*/

With Classify AS(
SELECT Participant_Code,Outage_Reason,Year,COUNT(*) AS Total_Number_Outages_Events,  
       ROUND(AVG(ABS(JULIANDAY(End_Time) - JULIANDAY(Start_Time))),2) AS Average_Outage_Duration_In_Days
FROM AEMR_Outage_Table
WHERE Status = 'Approved'
GROUP BY Participant_Code,Outage_Reason,Year
ORDER BY Total_Number_Outages_Events DESC
)

SELECT *,
CASE
    WHEN Average_Outage_Duration_In_Days > 1 THEN 'High Risk'
    WHEN Average_Outage_Duration_In_Days BETWEEN 0.5 AND 1 THEN 'Medium Risk'
    WHEN Average_Outage_Duration_In_Days BETWEEN 0 AND 0.5 THEN 'Low Risk'
    ELSE 'N/A'
END AS Risk_Classification
FROM Classify;

/* Q5: Classify each participant as either high, medium or low risk based off their approved average outage duration time and 
       Total number of Outage Events focus on Forced Outages*/
	   
With Classify As(
SELECT Participant_Code,Outage_Reason,Year,COUNT(*) as Total_Number_Outages_Events,  
       ROUND(AVG(ABS(JULIANDAY(End_Time) - JULIANDAY(Start_Time))),2) AS Average_Outage_Duration_In_Days
FROM AEMR_Outage_Table
WHERE Status = 'Approved'
GROUP BY Participant_Code,Outage_Reason,Year
ORDER BY Total_Number_Outages_Events DESC
)

SELECT *,
CASE
    WHEN Average_Outage_Duration_In_Days > 1 AND Outage_Reason = 'Forced'OR Total_Number_Outages_Events > 20 AND Outage_Reason = 'Forced' THEN 'High Risk'
    WHEN Average_Outage_Duration_In_Days BETWEEN 0.5 AND 1 AND Outage_Reason = 'Forced'OR Total_Number_Outages_Events BETWEEN 10 AND 20 AND Outage_Reason = 'Forced' THEN 'Medium Risk'
    WHEN Average_Outage_Duration_In_Days BETWEEN 0 AND 0.5 AND Outage_Reason = 'Forced'OR Total_Number_Outages_Events < 10 AND Outage_Reason = 'Forced' THEN 'Low Risk'
    ELSE 'N/A'
END AS Risk_Classification
FROM Classify
ORDER BY Average_Outage_Duration_In_Days DESC;

/* PART 2: ENERGY LOSSES AND MARKET RELIABILITY */

/* Q6: Calculate Proportion of Outages that have occurred over the 2016-2017 period */

SELECT Year,
COUNT(*) AS Total_Number_Outages, 
SUM(CASE WHEN Outage_Reason ='Forced' THEN 1 ELSE 0 END) AS Total_Number_Forced_Outage_Events,
ROUND(SUM(CASE WHEN Outage_Reason ='Forced' THEN 1 ELSE 0 END)*1.0/COUNT(*)*100,2) AS Pct_Outage_Forced


FROM AEMR_Outage_Table
WHERE Status = 'Approved' 
GROUP BY Year

/* Q7: Calculate total duration and  total energy lost (MW) for outages by participant code */

SELECT COUNT(*) AS Total_Number_Outages,
ROUND(SUM(ABS(Julianday(End_time)-Julianday(Start_Time))),2) AS Total_Duration_In_Days,
ROUND(SUM(Energy_Lost_MW),2) AS Total_Energy_Lost,
Outage_Reason, Participant_Code,Facility_Code,Year

FROM AEMR_Outage_Table
WHERE Status = 'Approved'
GROUP BY Outage_Reason, Participant_Code,Facility_Code,Year
ORDER BY Total_Duration_In_Days DESC,Year DESC

/* Q8: Calculate averag duration in days and average energy lost of all valid Forced Outages for each participant and facility*/

SELECT
ROUND(AVG(ABS(Julianday(End_time)-Julianday(Start_Time))),2) AS Avg_Duration_In_Days,
ROUND(AVG(Energy_Lost_MW),2) AS Avg_Energy_Lost,
Outage_Reason, Participant_Code,Facility_Code, Year

FROM AEMR_Outage_Table
WHERE Status = 'Approved' AND Outage_Reason = 'Forced'
GROUP BY Outage_Reason, Participant_Code,Facility_Code,Year
ORDER BY Avg_Energy_Lost DESC,Year DESC
LIMIT 10

/* Q9: Calculate Average energy lost and total energy lost for Forced Outage by participant and facility */

SELECT
ROUND(AVG(Energy_Lost_MW),2) AS Avg_Energy_Lost,
ROUND(SUM(Energy_Lost_MW),2) AS Total_Energy_Lost,
ROUND(SUM(Energy_Lost_MW)/(SELECT SUM(Energy_Lost_MW) FROM AEMR_Outage_Table WHERE Status = 'Approved' AND Outage_Reason = 'Forced')*100,2) AS Pct_Energy_Loss,
Outage_Reason, Participant_Code,Facility_Code,Year

FROM AEMR_Outage_Table
WHERE Status = 'Approved' AND Outage_Reason = 'Forced'
GROUP BY Outage_Reason, Participant_Code,Facility_Code,Year

ORDER BY Avg_Energy_Lost DESC,Year DESC

/* Q10: Identified the top 3 participants by Total Energy Loss being GW, MELK and AURICON.*/

SELECT
*
FROM(
SELECT 
Participant_Code, Facility_Code, Description_Of_Outage,
ROUND(SUM(Energy_Lost_MW),2) AS Total_Energy_Lost,
ROUND(SUM(Energy_Lost_MW)/(SELECT SUM(Energy_Lost_MW) FROM AEMR_Outage_Table WHERE Status = 'Approved' AND Outage_Reason = 'Forced')*100,2) AS Pct_Energy_Loss,
RANK() Over (PARTITION BY Participant_Code, Facility_Code ORDER BY SUM(Energy_Lost_MW) DESC) AS Ranking
FROM AEMR_Outage_Table
WHERE Participant_Code IN ('GW','MELK','AURICON') AND Status = 'Approved' AND Outage_Reason = 'Forced'
GROUP BY Participant_Code,Facility_Code, Description_Of_Outage
ORDER BY Participant_Code, Total_Energy_Lost DESC)
WHERE Ranking = 1



