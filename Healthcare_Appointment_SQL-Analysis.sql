-- ============================================
-- Healthcare Appointment & Patient Operations Analysis
-- SQL Business Analysis
-- Analyst: Precious Onyedum
-- ============================================

-- ============================================
-- 1. Database Setup
-- ============================================
CREATE DATABASE Healthcare_Operations;

USE Healthcare_Operations;

CREATE TABLE healthcare_appointments (
    Patient_ID VARCHAR(20),
    Age INT,
    Gender VARCHAR(20),
    Patient_Type VARCHAR(30),
    Insurance_Type VARCHAR(30),
    Appointment_ID VARCHAR(20),
    Scheduled_Date VARCHAR(10),
    Appointment_Date VARCHAR(10),
    Appointment_Time TIME,
    Appointment_Type VARCHAR(40),
    Department VARCHAR(50),
    Doctor_ID VARCHAR(20),
    Appointment_Status VARCHAR(30),
    Days_Between_Scheduling_and_Appointment INT,
    Arrival_Time TIME,
    Wait_Time_Minutes INT,
    Consultation_Duration_Minutes INT,
    Cancellation_Reason VARCHAR(100),
    No_Show_Reason VARCHAR(100),
    Visit_Reason VARCHAR(100),
    Diagnosis_Category VARCHAR(100),
    Treatment_Type VARCHAR(100),
    Follow_Up_Required VARCHAR(10),
    Consultation_Fee DECIMAL(12,2),
    Insurance_Covered_Amount DECIMAL(12,2),
    Patient_Payment DECIMAL(12,2),
    State VARCHAR(50),
    City VARCHAR(50),
    Scheduled_Date_Clean DATE,
    Appointment_Date_Clean DATE
);

SHOW TABLES;

DESCRIBE healthcare_appointments;

-- ============================================
-- 2. Data Import
-- ============================================
SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'C:/Users/USER/Documents/healthcare appointment and operations portfolio project/healthcare_appointments.csv'
INTO TABLE healthcare_appointments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Patient_ID, Age, Gender, Patient_Type, Insurance_Type, Appointment_ID,
 Scheduled_Date, Appointment_Date, Appointment_Time, Appointment_Type,
 Department, Doctor_ID, Appointment_Status,
 Days_Between_Scheduling_and_Appointment, @Arrival_Time, @Wait_Time,
 @Consult_Duration, @Cancel_Reason, @NoShow_Reason, Visit_Reason,
 @Diagnosis, @Treatment, @FollowUp, @Fee, @Covered, @Payment, State, City)
SET
 Arrival_Time = NULLIF(@Arrival_Time, ''),
 Wait_Time_Minutes = NULLIF(@Wait_Time, ''),
 Consultation_Duration_Minutes = NULLIF(@Consult_Duration, ''),
 Cancellation_Reason = NULLIF(@Cancel_Reason, ''),
 No_Show_Reason = NULLIF(@NoShow_Reason, ''),
 Diagnosis_Category = NULLIF(@Diagnosis, ''),
 Treatment_Type = NULLIF(@Treatment, ''),
 Follow_Up_Required = NULLIF(@FollowUp, ''),
 Consultation_Fee = NULLIF(@Fee, ''),
 Insurance_Covered_Amount = NULLIF(@Covered, ''),
 Patient_Payment = NULLIF(@Payment, '');
 
 SELECT COUNT(*) AS Rows_Loaded
FROM healthcare_appointments;
-- Result: 10,000 rows loaded.

-- ============================================
-- 3. Data Cleaning
-- ============================================
-- Cleaning 1 — Convert Date Text into Proper Dates
-- Objective: Convert the dd-mm-yy text dates into DATE columns so that date comparisons and calculations work correctly.
-- Safe update mode must be switched off in the same session before running an UPDATE without a key column (error 1175).
SET SQL_SAFE_UPDATES = 0;

UPDATE healthcare_appointments
SET Scheduled_Date_Clean = STR_TO_DATE(Scheduled_Date, '%d-%m-%y'),
    Appointment_Date_Clean = STR_TO_DATE(Appointment_Date, '%d-%m-%y');

SELECT MIN(Scheduled_Date_Clean) AS First_Scheduled,
       MAX(Appointment_Date_Clean) AS Last_Appointment,
       SUM(Appointment_Date_Clean < Scheduled_Date_Clean) AS Invalid_Sequence,
       SUM(Scheduled_Date_Clean IS NULL OR Appointment_Date_Clean IS NULL) AS Failed_Conversions
FROM healthcare_appointments;
-- Result:
-- First scheduled date 2024-01-01, last appointment date 2025-12-31, 0 invalid sequences and 0 failed conversions.
-- Interpretation:
-- All 10,000 dates converted successfully. An earlier import that let MySQL read the dates directly misread the dd-mm-yy format
-- (dates spanning 2001-2031) and falsely reported 4,323 records (43.2%) with an appointment before its scheduled date.
-- That was an import error, not a data error. From this point, all date analysis uses the _Clean columns.

-- Cleaning 2 — Check for Hidden Line-Ending Characters
-- Objective: Confirm that the last column (City) was not loaded with a hidden carriage-return character.
SELECT COUNT(*) AS Rows_With_Hidden_Carriage_Return
FROM healthcare_appointments
WHERE City LIKE CONCAT('%', CHAR(13), '%');
-- Result: 0 rows.
-- Interpretation: City values are clean. (If this returns 10,000, the file was loaded with the wrong line ending; see Section 2.)

-- Cleaning 3 — Wait Time Recorded as Zero for Non-Attended Appointments
-- Objective: Check whether wait time is recorded only for appointments that were actually attended.
SELECT Appointment_Status,
       COUNT(Wait_Time_Minutes) AS Wait_Time_Records,
       MIN(Wait_Time_Minutes) AS Min_Wait,
       MAX(Wait_Time_Minutes) AS Max_Wait,
       ROUND(AVG(Wait_Time_Minutes), 1) AS Avg_Wait
FROM healthcare_appointments
GROUP BY Appointment_Status;
-- Result (before cleaning):
-- Cancelled: 797 records, min 0, max 0, average 0.0
-- No-Show: 871 records, min 0, max 0, average 0.0
-- Rescheduled: 516 records, min 0, max 0, average 0.0
-- Completed: 7,816 records, min 5, max 147, average 63.1
-- Interpretation:
-- The 2,184 appointments that did not take place carry a wait time of 0 instead of NULL. These are placeholders, not real 0-minute waits.
-- Left in place, they would pull the average wait time down (49.3 minutes instead of 63.1) and inflate the count of appointments
-- with a recorded wait time. They are set to NULL so that wait time applies only to completed appointments.
SET SQL_SAFE_UPDATES = 0;

UPDATE healthcare_appointments
SET Wait_Time_Minutes = NULL
WHERE Appointment_Status <> 'Completed';

SELECT Appointment_Status,
       COUNT(Wait_Time_Minutes) AS Wait_Time_Records,
       MIN(Wait_Time_Minutes) AS Min_Wait,
       MAX(Wait_Time_Minutes) AS Max_Wait,
       ROUND(AVG(Wait_Time_Minutes), 1) AS Avg_Wait
FROM healthcare_appointments
GROUP BY Appointment_Status;
-- Result (after cleaning):
-- Completed: 7,816 records, min 5, max 147, average 63.1. Cancelled, No-Show and Rescheduled: 0 records (NULL).

SET SQL_SAFE_UPDATES = 1;

-- ============================================
-- 4. Exploratory Data Analysis
-- Before analysis, the dataset was checked for completeness, duplication, and structural integrity to confirm it was fit for business analysis.
-- ============================================
-- EDA 1 — Determine Total Appointment Volume
-- Objective: Determine the total number of appointment records in the dataset.
SELECT COUNT(*) AS Total_Appointments
FROM healthcare_appointments;
-- Result:
-- 10,000 appointments.
-- Interpretation:
-- The dataset contains 10,000 appointment records for analysis.

-- EDA 2 — Determine Patient and Appointment Uniqueness
-- Objective: Determine the number of unique appointments and unique patients.
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Appointment_ID) AS Unique_Appointments,
    COUNT(DISTINCT Patient_ID) AS Unique_Patients
FROM healthcare_appointments;
-- Result:
-- 10,000 total rows, 10,000 unique appointments and 5,123 unique patients.
-- Interpretation:
-- There are 10,000 appointment records but fewer (5,123) unique patients, indicating that some patients had multiple appointments.

-- EDA 3 — Explore Categorical Value Distributions
-- Objective: Identify all distinct values within key categorical fields to check for unexpected categories, spelling inconsistencies, or irregular
-- entries before analysis.
SELECT DISTINCT Appointment_Status
FROM healthcare_appointments
ORDER BY Appointment_Status;
SELECT DISTINCT Department
FROM healthcare_appointments
ORDER BY Department;
SELECT DISTINCT Patient_Type
FROM healthcare_appointments;
SELECT Insurance_Type, COUNT(*) AS Appointments
FROM healthcare_appointments
GROUP BY Insurance_Type
ORDER BY Appointments DESC;
SELECT DISTINCT Appointment_Type
FROM healthcare_appointments;
SELECT DISTINCT Follow_Up_Required
FROM healthcare_appointments;
-- Result:
-- . Appointment_Status: Completed, No-Show, Cancelled, Rescheduled
-- . Department: Cardiology, Dental, Dermatology, General Medicine, Gynecology, Neurology, Orthopedics, Pediatrics
-- . Patient_Type: New Patient, Returning Patient
-- . Insurance_Type: HMO (2,911), Private Insurance (2,498), Self-Pay (2,066), Government (1,497), None (1,028)
-- . Appointment_Type: General Consultation, Follow-Up, Specialist Consultation, Preventive Care, Diagnostic
-- . Follow_Up_Required: Yes, No, NULL (NULL for the 2,184 appointments that were not completed)
-- Interpretation:
-- The reviewed categorical fields contain a consistent set of expected categories, with no unexpected values or spelling variations.
-- "None" in Insurance_Type is a real category (patients with no insurance), not missing data. The NULLs in Follow_Up_Required
-- correspond to appointments that did not take place.

-- EDA 4 — Check Age Value Ranges
-- Objective: Check whether the age values are within realistic ranges.
SELECT
    MIN(Age) AS Min_Age,
    MAX(Age) AS Max_Age,
    ROUND(AVG(Age), 1) AS Average_Age
FROM healthcare_appointments;
-- Result:
-- Minimum age 1, maximum age 85, average age 43.0.
-- Interpretation:
-- Patient ages range from 1 to 85 years, with an average of 43, reflecting a broad patient population spanning pediatric to elderly care.


-- EDA 5 — Check Wait Time Value Range
-- Objective: Check whether the wait time values are within realistic ranges. Wait time applies to completed appointments only (see Cleaning 3).
SELECT
    COUNT(Wait_Time_Minutes) AS Appointments_With_Wait_Time,
    MIN(Wait_Time_Minutes) AS Min_Wait_Time,
    MAX(Wait_Time_Minutes) AS Max_Wait_Time,
    ROUND(AVG(Wait_Time_Minutes), 1) AS Average_Wait_Time
FROM healthcare_appointments;
-- Result:
-- 7,816 appointments with a recorded wait time; minimum 5, maximum 147, average 63.1 minutes.
-- Interpretation:
-- Among completed appointments, waits range from 5 to 147 minutes with an average of 63.1 minutes. This indicates that patient waiting time
-- is an important operational area for further analysis.

-- EDA 6 — Identify Potential Outliers
-- Objective: Determine whether any wait times are unusually high (over 120 minutes) and may warrant further investigation.
SELECT
    Appointment_ID,
    Department,
    Wait_Time_Minutes
FROM healthcare_appointments
WHERE Wait_Time_Minutes > 120
ORDER BY Wait_Time_Minutes DESC;
-- Result:
-- 413 completed appointments (5.3% of 7,816) had a wait time above 120 minutes; the maximum was 147 minutes.
-- Interpretation:
-- These values appear plausible in a healthcare setting and were not treated as data-quality errors. However, prolonged waiting times warrant 
-- further investigation by department and appointment type.

-- EDA 7 — Validate Date Range and Chronological Consistency
-- Objective: Verify the date range and confirm that appointment dates do not occur before their corresponding scheduled dates.
SELECT
    MIN(Scheduled_Date_Clean) AS First_Scheduled_Date,
    MAX(Scheduled_Date_Clean) AS Last_Scheduled_Date,
    MIN(Appointment_Date_Clean) AS First_Appointment_Date,
    MAX(Appointment_Date_Clean) AS Last_Appointment_Date
FROM healthcare_appointments;
-- Result:
-- Scheduled dates range from 2024-01-01 to 2025-12-31, and appointment dates range from 2024-01-05 to 2025-12-31.
-- Interpretation:
-- The data covers two full years, 2024 and 2025.

SELECT COUNT(*) AS Invalid_Date_Sequence
FROM healthcare_appointments
WHERE Appointment_Date_Clean < Scheduled_Date_Clean;
-- Result:
-- 0 of the 10,000 records have an appointment date earlier than the scheduled date.
-- Interpretation:
-- Dates are chronologically consistent. The 43.2% "invalid" rate found in an earlier version of this analysis was caused by the
-- dd-mm-yy import problem described in Cleaning 1, not by the data itself.


-- ============================================
-- 5. Data Quality Assessment
-- ============================================
-- Data Quality Assessment 1 — Check for Missing Values in Operational Fields
-- Objective: Determine whether key operational and financial fields are populated only where they should be.
SELECT
    Appointment_Status,
    COUNT(*) AS Total,
    COUNT(Arrival_Time) AS Arrival_Time_Count,
    COUNT(Wait_Time_Minutes) AS Wait_Time_Count,
    COUNT(Consultation_Duration_Minutes) AS Duration_Count,
    COUNT(Consultation_Fee) AS Fee_Count
FROM healthcare_appointments
GROUP BY Appointment_Status;
-- Result:
-- Completed: 7,816 appointments, with Arrival_Time, Wait_Time_Minutes, Consultation_Duration_Minutes and Consultation_Fee all recorded (7,816 each).
-- Cancelled (797), No-Show (871) and Rescheduled (516): none of the four fields recorded.
-- Interpretation:
-- The four fields are missing in 2,184 records (10,000 - 7,816). This is expected, since they only apply to appointments that were actually
-- attended. This confirms that the missing values are logically consistent with appointment outcomes and do not indicate a data-quality problem.
-- (Wait_Time_Minutes meets this standard only after the zero placeholders were set to NULL in Cleaning 3.)

-- Data Quality Assessment 2 — Check for Duplicate Appointments
-- Objective: Identify whether any Appointment IDs appear more than once.
SELECT
    Appointment_ID,
    COUNT(*) AS Duplicate_Count
FROM healthcare_appointments
GROUP BY Appointment_ID
HAVING COUNT(*) > 1;
-- Result:
-- No duplicates found (0 rows returned).
-- Interpretation:
-- There were no duplicate appointment IDs recorded.


-- Data Quality Assessment 3 — Validate Financial Consistency
-- Objective: Confirm that the patient payment equals the consultation fee minus the insurance-covered amount for completed appointments.
SELECT COUNT(*) AS Financial_Mismatch
FROM healthcare_appointments
WHERE Appointment_Status = 'Completed'
  AND ABS(Consultation_Fee - Insurance_Covered_Amount - Patient_Payment) > 0.01;
-- Result:
-- 0 mismatches.
-- Interpretation:
-- Financial values are internally consistent for every completed appointment.

-- Data Quality Assessment 4 — Validate Stored Scheduling Lead Time Against the Dates
-- Objective: Check whether Days_Between_Scheduling_and_Appointment matches the difference between the two dates.
SELECT COUNT(*) AS Lead_Time_Mismatch
FROM healthcare_appointments
WHERE DATEDIFF(Appointment_Date_Clean, Scheduled_Date_Clean) <> Days_Between_Scheduling_and_Appointment;

SELECT Appointment_Date_Clean, COUNT(*) AS Mismatched_Records
FROM healthcare_appointments
WHERE DATEDIFF(Appointment_Date_Clean, Scheduled_Date_Clean) <> Days_Between_Scheduling_and_Appointment
GROUP BY Appointment_Date_Clean;
-- Result:
-- 285 records have a stored lead time that does not match their dates. All 285 have an appointment date of 2025-12-31, and in every case the
-- stored lead time is larger than the real gap between the dates.
-- Interpretation:
-- The stored column is unreliable for these records. Scheduling lead time should therefore be calculated from the dates with
-- DATEDIFF(Appointment_Date_Clean, Scheduled_Date_Clean) rather than taken from the stored column.

-- Data Quality Assessment 5 — Check for an Unusual Concentration of Appointments on One Date
-- Objective: Check appointment volume around the end of the date range.
SELECT Appointment_Date_Clean, COUNT(*) AS Appointments
FROM healthcare_appointments
WHERE Appointment_Date_Clean >= '2025-12-25'
GROUP BY Appointment_Date_Clean
ORDER BY Appointment_Date_Clean;
-- Result:
-- 304 appointments fall on 2025-12-31, compared with 10 to 17 on the days immediately before it.
-- Interpretation:
-- The pile-up on the last day of the dataset is unusual and appears to be linked to the 285 lead-time mismatches above. It distorts monthly and 
-- daily trends, so 2025-12-31 should be excluded or annotated in trend analysis.

-- Data Quality Assessment 6 — Check Patient Type Consistency
-- Objective: Check whether Patient_Type reflects each patient's visit history.
SELECT COUNT(*) AS Patients_With_Multiple_New_Visits
FROM (
    SELECT Patient_ID
    FROM healthcare_appointments
    WHERE Patient_Type = 'New Patient'
    GROUP BY Patient_ID
    HAVING COUNT(*) > 1
) AS multi_new;
-- Result:
-- 1,636 of the 5,123 patients are recorded as "New Patient" on more than one appointment.
-- Interpretation:
-- Patient_Type describes each appointment as recorded, not a patient's history. Patient type comparisons should therefore be read at
-- appointment level (appointments flagged as new or returning), not as a count of distinct new or returning patients.

-- ============================================
-- 6. Business Questions
-- ============================================
-- Business Question 1 — Appointment Outcomes
-- Objective: Determine the volume and percentage of appointments by appointment status.
SELECT
    Appointment_Status,
    COUNT(*) AS Appointment_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare_appointments), 1) AS Percentage
FROM healthcare_appointments
GROUP BY Appointment_Status
ORDER BY Appointment_Count DESC;
-- Result:
-- Completed: 7,816 (78.2%), No-Show: 871 (8.7%), Cancelled: 797 (8.0%) and Rescheduled: 516 (5.2%).
-- Business Insight:
-- The majority of appointments were completed, accounting for 78.2% of all appointments. However, 21.8% of appointments did not result in a
-- completed visit, consisting of no-shows, cancellations, and rescheduled appointments. The 8.7% no-show rate and 8.0% cancellation rate indicate
-- that missed and cancelled appointments represent a meaningful operational issue that may affect scheduling efficiency, resource utilization,
-- and patient access.

-- Business Question 2 — Department No-Show Performance
-- Objective: Compare no-show rates across departments to identify areas with higher appointment non-attendance.
SELECT
    Department,
    COUNT(*) AS Total_Appointments,
    SUM(CASE
        WHEN Appointment_Status = 'No-Show' THEN 1
        ELSE 0
    END) AS No_Show_Count,
    ROUND(
        SUM(CASE
            WHEN Appointment_Status = 'No-Show' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        1
    ) AS No_Show_Rate
FROM healthcare_appointments
GROUP BY Department
ORDER BY No_Show_Rate DESC;
-- Result:
-- Dermatology recorded the highest no-show rate at 9.3%, followed by Pediatrics (9.1%), Dental (9.0%), and Orthopedics (8.9%). Neurology had the
-- lowest no-show rate at 7.9%. Overall, the difference between departments was relatively narrow, ranging from 7.9% to 9.3%, with no department
-- showing a major deviation from the others.
-- Business Insight:
-- No-show rates are relatively consistent across departments, suggesting that appointment non-attendance is a broader operational issue rather than
-- one concentrated in a particular specialty. Dermatology and Pediatrics may be useful starting points for targeted interventions, but further
-- analysis of factors such as scheduling lead time, appointment timing, patient type, and no-show reasons would be needed to determine the
-- underlying drivers.

-- Business Question 3 — Why Are Patients Missing Appointments?
-- Objective: Identify the most common reasons associated with missed appointments.
SELECT
    No_Show_Reason,
    COUNT(*) AS No_Show_Count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM healthcare_appointments
         WHERE Appointment_Status = 'No-Show'),
        1
    ) AS Percentage
FROM healthcare_appointments
WHERE Appointment_Status = 'No-Show'
GROUP BY No_Show_Reason
ORDER BY No_Show_Count DESC;
-- Result:
-- Transportation issues were the leading recorded reason for no-shows, accounting for 153 cases (17.6%). This was followed by Unknown (17.2%),
-- Cost Concern (17.0%), Forgot Appointment (16.9%), Work/School Conflict (16.4%), and Feeling Better (14.9%). The relatively small 2.7
-- percentage-point difference between the highest and lowest categories indicates that no single reason dominates the no-show population.
-- Business Insight:
-- No-shows appear to have multiple contributing factors, spanning logistical, financial, and behavioral challenges. This suggests that a single
-- intervention may not address the full problem. Potential responses could include appointment reminders for patients who forget appointments,
-- flexible scheduling or telehealth options where appropriate for transportation and work/school conflicts, and clearer communication of expected 
-- costs for patients with financial concerns. The relatively high proportion of Unknown reasons (17.2%) also highlights an opportunity to improve 
-- the capture of no-show reasons, which would make future operational analysis more actionable.

-- Business Question 4 — What Are the Reasons Appointments Were Cancelled?
-- Objective: Identify the most common reasons for cancelled appointments.
SELECT
    Cancellation_Reason,
    COUNT(*) AS Cancellation_Count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM healthcare_appointments
         WHERE Appointment_Status = 'Cancelled'),
        1
    ) AS Percentage
FROM healthcare_appointments
WHERE Appointment_Status = 'Cancelled'
GROUP BY Cancellation_Reason
ORDER BY Cancellation_Count DESC;
-- Result:
-- Cost Concern was the most common cancellation reason, accounting for 167 cases (21.0%), followed by Transportation Issue (20.2%),
-- Schedule Conflict (20.1%), Patient Request (19.7%), and Doctor Unavailable (19.1%). The distribution was relatively even, with less than a
-- 2-percentage-point difference between the highest and lowest categories.
-- Business Insight:
-- Cancellation reasons are broadly distributed across patient-related factors, including financial, transportation, scheduling, and personal
-- preferences, as well as the facility-side issue of doctor availability. Cost Concern stands out because it is also one of the leading reasons
-- for no-shows, suggesting that financial barriers may be an important area for further investigation. Potential actions could include clearer
-- cost communication, insurance verification at booking, and exploring appropriate payment options. The Doctor Unavailable category, although
-- the smallest, is particularly relevant from an operational perspective because it is directly influenced by hospital scheduling.
-- Further analysis by department and doctor could determine whether these cancellations are concentrated in specific areas.

-- Business Question 5 — Which Departments Have the Longest Average Patient Waiting Times?
-- Objective: Compare average patient waiting times across departments to identify potential operational bottlenecks.
-- Wait time applies to completed appointments only.
SELECT
    Department,
    COUNT(Wait_Time_Minutes) AS Completed_Appointments,
    ROUND(AVG(Wait_Time_Minutes), 1) AS Average_Wait_Time,
    MAX(Wait_Time_Minutes) AS Maximum_Wait_Time
FROM healthcare_appointments
WHERE Wait_Time_Minutes IS NOT NULL
GROUP BY Department
ORDER BY Average_Wait_Time DESC;
-- Result:
-- Dental recorded the highest average patient wait time at 64.6 minutes, followed by Orthopedics (64.3), Neurology (64.0), Gynecology (63.7),
-- General Medicine and Pediatrics (62.5 each), and Cardiology (61.5). Dermatology had the lowest average wait time at 61.4 minutes.
-- The difference between the highest and lowest departmental averages was only 3.2 minutes. Maximum wait times were also consistently high
-- across departments, reaching 141 to 147 minutes.
-- Business Insight:
-- Patient waiting times appear to reflect a hospital-wide operational pattern rather than a major department-specific bottleneck.
-- The relatively narrow range in average wait times, combined with high maximum waits across departments, suggests that broader factors such as
-- scheduling density, staffing capacity, or patient-flow processes may warrant investigation. Hospital-wide improvements to appointment spacing,
-- scheduling buffers, and patient flow could therefore have broader impact than isolated departmental interventions. Dental, which recorded the
-- highest average wait time, could nevertheless be considered for a pilot intervention.

-- Business Question 6 — Do New and Returning Patient Appointments Have Different Attendance Patterns?
-- Objective: Compare appointment outcomes between appointments flagged as new patient and returning patient (see Data Quality Assessment 6).
SELECT
    Patient_Type,
    COUNT(*) AS Total_Appointments,
    SUM(CASE WHEN Appointment_Status = 'Completed' THEN 1 ELSE 0 END) AS Completed,
    SUM(CASE WHEN Appointment_Status = 'No-Show' THEN 1 ELSE 0 END) AS No_Shows,
    SUM(CASE WHEN Appointment_Status = 'Cancelled' THEN 1 ELSE 0 END) AS Cancelled,
    SUM(CASE WHEN Appointment_Status = 'Rescheduled' THEN 1 ELSE 0 END) AS Rescheduled,
    ROUND(SUM(CASE WHEN Appointment_Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Completion_Rate,
    ROUND(SUM(CASE WHEN Appointment_Status = 'No-Show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS No_Show_Rate,
    ROUND(SUM(CASE WHEN Appointment_Status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Cancellation_Rate
FROM healthcare_appointments
GROUP BY Patient_Type
ORDER BY Completion_Rate DESC;
-- Result:
-- Returning Patient: 3,782 appointments (2,965 completed, 323 no-shows, 306 cancelled, 188 rescheduled); completion rate 78.4%,
-- no-show rate 8.5%, cancellation rate 8.1%.
-- New Patient: 6,218 appointments (4,851 completed, 548 no-shows, 491 cancelled, 328 rescheduled); completion rate 78.0%,
-- no-show rate 8.8%, cancellation rate 7.9%.
-- Business Insight:
-- New and returning patient appointments show very similar attendance patterns, with a completion-rate difference of only 0.4 percentage points.
-- Patient type alone is therefore unlikely to be a meaningful predictor of missed appointments in this dataset, and attendance-improvement
-- strategies could be applied broadly rather than being heavily differentiated. The finding also challenges the assumption that first-time
-- patients necessarily have substantially higher no-show risk, highlighting the value of using actual appointment data rather than assumptions.


-- Business Question 7 — How Much Consultation Revenue Was Generated, and How Does It Vary Across Departments?
-- Objective: Measure consultation revenue and compare financial performance across departments.
SELECT
    Department,
    COUNT(Consultation_Fee) AS Completed_Appointments,
    ROUND(SUM(Consultation_Fee), 2) AS Total_Consultation_Revenue,
    ROUND(AVG(Consultation_Fee), 2) AS Average_Consultation_Fee,
    ROUND(SUM(Insurance_Covered_Amount), 2) AS Insurance_Revenue,
    ROUND(SUM(Patient_Payment), 2) AS Patient_Revenue
FROM healthcare_appointments
WHERE Appointment_Status = 'Completed'
GROUP BY Department
ORDER BY Total_Consultation_Revenue DESC;
-- Result:
-- General Medicine generated the highest total consultation revenue at N36.77 million, despite having the lowest average consultation fee of
-- N20,026.14. Its strong revenue performance was primarily volume-driven, with 1,836 completed appointments, substantially more than other
-- departments. Neurology recorded the highest average consultation fee at N46,034.53, but its lower volume of 695 completed appointments resulted
-- in total revenue of N31.99 million, placing it third overall. Dermatology generated the lowest total revenue at N19.36 million, reflecting its
-- relatively low volume of 619 completed appointments.
-- Business Insight:
-- Consultation revenue appears to be influenced more by appointment volume than consultation pricing alone. General Medicine's high-volume, lower
-- fee model generated more total revenue than Neurology's higher-fee, lower-volume model. This suggests two potential revenue-growth opportunities:
-- improving capacity and appointment utilization in higher-fee, lower-volume departments, while protecting the high patient volume that drives
-- revenue in General Medicine. The findings from the earlier attendance analysis also suggest that reducing missed appointments could be an
-- important avenue for protecting revenue, particularly where unused appointment capacity represents lost consultation opportunities.

-- Business Question 8a — Which States Have the Highest Appointment Volumes?
-- Objective: Identify the states with the highest appointment volumes.
SELECT
    State,
    COUNT(*) AS Appointment_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare_appointments), 1) AS Percentage
FROM healthcare_appointments
GROUP BY State
ORDER BY Appointment_Count DESC;
-- Result:
-- The dataset covers 18 states. Plateau recorded the highest appointment volume with 608 appointments (6.1%), followed by Lagos and Kwara with
-- 579 appointments each (5.8%). Edo, Anambra, Enugu, Ondo and Kano each recorded approximately 5.7% of total appointments. The lowest volume was
-- in Akwa Ibom (493 appointments, 4.9%). Overall, appointment volumes were relatively evenly distributed across states, with no single state
-- accounting for a dominant share.
-- Business Insight:
-- Appointment activity is broadly distributed across the states represented in the dataset rather than being concentrated in one major location.
-- Interestingly, Lagos did not substantially outperform the other states despite its large population, indicating that appointment volume in this
-- synthetic dataset is not strongly concentrated by state. Geographic location may therefore be more useful for understanding service
-- distribution and patient reach than for identifying a single dominant market.

-- Business Question 8b — Which Cities Have the Highest Appointment Volumes?
-- Objective: Identify the cities with the highest appointment volumes.
SELECT
    City,
    COUNT(*) AS Appointment_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM healthcare_appointments), 1) AS Percentage
FROM healthcare_appointments
GROUP BY City
ORDER BY Appointment_Count DESC
LIMIT 10;
-- Result:
-- Jos recorded the highest appointment volume with 608 appointments (6.1%), followed by Lagos and Ilorin with 579 appointments each (5.8%). Benin
-- City, Awka, Enugu, and Akure each accounted for approximately 5.7% of appointments, with Kano also among the higher-volume cities. The dataset
-- contains 18 cities, exactly one per state, so city-level counts match their state totals.
-- Business Insight:
-- The geographic analysis shows that appointment volume is relatively evenly distributed across states, but each state is represented by a single
-- city. Operational planning should therefore consider the city or facility level when evaluating staffing, scheduling capacity, and service demand.
-- This is also a limitation of the dataset: it represents geographic activity at a primary-city level rather than a broad distribution of patients
-- across multiple locations within each state.

-- Business Question 9 — How Does Appointment Volume Change by Month?
-- Objective: Examine monthly appointment volume across 2024 and 2025, including the effect of the 2025-12-31 pile-up (Data Quality Assessment 5).
SELECT
    DATE_FORMAT(Appointment_Date_Clean, '%Y-%m') AS Appointment_Month,
    COUNT(*) AS Appointments,
    SUM(CASE WHEN Appointment_Date_Clean <> '2025-12-31' THEN 1 ELSE 0 END) AS Appointments_Excluding_31_Dec_2025
FROM healthcare_appointments
GROUP BY Appointment_Month
ORDER BY Appointment_Month;
-- Result:
-- 2024 recorded 4,702 appointments and 2025 recorded 5,298. Most months fall between 355 and 473 appointments. Two months stand out:
-- January 2024 (132 appointments, a partial first month starting on 5 January) and December 2025 (718 appointments, of which 304 fall on 31 December;
-- excluding that date, December 2025 has 414).
-- Business Insight:
-- Once the data-entry artefacts are set aside, monthly demand is fairly steady at roughly 380 to 470 appointments, with no strong seasonal swings.
-- The apparent December 2025 spike should not be interpreted as real demand, and the low January 2024 figure reflects the start of the dataset.

-- Business Question 10 — Does Scheduling Lead Time Affect No-Show Rates?
-- Objective: Compare no-show rates across scheduling lead-time groups, with lead time calculated from the clean dates.
SELECT
    CASE
        WHEN DATEDIFF(Appointment_Date_Clean, Scheduled_Date_Clean) <= 7 THEN '0-7 days'
        WHEN DATEDIFF(Appointment_Date_Clean, Scheduled_Date_Clean) <= 14 THEN '8-14 days'
        WHEN DATEDIFF(Appointment_Date_Clean, Scheduled_Date_Clean) <= 30 THEN '15-30 days'
        ELSE '31+ days'
    END AS Lead_Time_Group,
    COUNT(*) AS Appointments,
    SUM(CASE WHEN Appointment_Status = 'No-Show' THEN 1 ELSE 0 END) AS No_Shows,
    ROUND(SUM(CASE WHEN Appointment_Status = 'No-Show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS No_Show_Rate
FROM healthcare_appointments
GROUP BY Lead_Time_Group
ORDER BY MIN(DATEDIFF(Appointment_Date_Clean, Scheduled_Date_Clean));
-- Result:
-- 0-7 days: 1,182 appointments, 114 no-shows (9.6%). 8-14 days: 2,177 appointments, 178 no-shows (8.2%).
-- 15-30 days: 3,930 appointments, 364 no-shows (9.3%). 31+ days: 2,711 appointments, 215 no-shows (7.9%).
-- Business Insight:
-- No-show rates vary between 7.9% and 9.6% across lead-time groups without a steady rise or fall as lead time increases. Scheduling lead time
-- alone does not appear to drive no-shows in this dataset, which is consistent with the earlier finding that non-attendance is a broad
-- operational issue rather than one tied to a single factor.

-- ============================================
-- 7. Key Insights
-- ============================================
-- 1. Appointment completion was relatively high, but missed appointments remain significant
-- 78.2% of appointments were completed, while 21.8% resulted in a no-show, cancellation, or rescheduling. No-shows accounted for 8.7% and
-- cancellations for 8.0% of all appointments.
-- Business implication:
-- A meaningful proportion of scheduled capacity did not convert into completed visits, creating potential opportunities to improve appointment
-- utilization and patient access.

-- 2. No-show rates were broadly consistent across departments
-- Dermatology had the highest no-show rate at 9.3%, while Neurology had the lowest at 7.9%. The relatively narrow 1.4-percentage-point range
-- suggests that no-shows are not concentrated in one particular department.
-- Business implication:
-- Attendance improvement should be considered as a broader operational issue rather than focusing exclusively on one specialty.

-- 3. No-shows had multiple contributing reasons
-- Transportation issues were the leading recorded reason for no-shows at 17.6%, followed closely by Unknown (17.2%), Cost Concern (17.0%), Forgot
-- Appointment (16.9%), Work/School Conflict (16.4%), and Feeling Better (14.9%).
-- Business implication:
-- Because no single reason dominates, a combination of approaches may be more appropriate than relying on one intervention.
-- The relatively high Unknown category also suggests that improving reason capture could strengthen future analysis.

-- 4. Cancellation reasons were also widely distributed
-- Cost Concern was the most common cancellation reason at 21.0%, followed by Transportation Issue (20.2%) and Schedule Conflict (20.1%). Doctor
-- Unavailable was the lowest at 19.1%, but the overall distribution was relatively even.
-- Business implication:
-- Cancellations appear to result from a mixture of patient-related and operational factors. Cost, transportation, scheduling, and provider
-- availability all warrant attention.

-- 5. Waiting times were long across the hospital rather than in one department
-- Completed appointments waited 63.1 minutes on average. Dental had the highest average at 64.6 minutes, compared with 61.4 minutes in
-- Dermatology, a difference of only 3.2 minutes. 413 completed visits (5.3%) waited more than 120 minutes, with maximum waits of 141 to 147
-- minutes across departments.
-- Business implication:
-- The consistency across departments suggests that broader patient-flow, scheduling, or capacity factors may be worth investigating rather
-- than treating waiting time as an isolated departmental problem.

-- 6. New and returning patient appointments had almost identical attendance patterns
-- Returning patient appointments had a completion rate of 78.4%, compared with 78.0% for new patient appointments. No-show rates were also very
-- close: 8.5% for returning versus 8.8% for new.
-- Business implication:
-- Patient type alone does not appear to be a strong differentiator of attendance behavior in this dataset. Attendance strategies could therefore
-- be designed broadly rather than heavily separating new and returning patients.

-- 7. Revenue was strongly influenced by appointment volume
-- General Medicine generated the highest total consultation revenue at approximately N36.77 million, despite having the lowest average consultation
-- fee of N20,026.14. This was driven by its high volume of 1,836 completed appointments.
-- Neurology had the highest average consultation fee at approximately N46,034.53, but its lower volume of 695 completed appointments resulted in
-- total revenue of approximately N31.99 million.
-- Business implication:
-- Revenue performance depends not only on pricing but also on appointment volume and capacity utilization. Higher-fee departments may have
-- opportunities to increase revenue through stronger appointment utilization.

-- 8. Geographic activity was relatively balanced, with one city per state
-- Plateau recorded the highest state appointment volume with 608 appointments (6.1%), while Lagos and Kwara each recorded 579 appointments (5.8%).
-- The dataset covers 18 states and 18 cities, one city per state.
-- Business implication:
-- Appointment demand is relatively evenly distributed across the states represented. This should be considered when evaluating geographic demand,
-- staffing, and operational capacity.

-- 9. Scheduling lead time did not clearly drive no-shows
-- No-show rates ranged from 7.9% to 9.6% across lead-time groups, with no steady trend as lead time increased.
-- Business implication:
-- Reducing lead time alone is unlikely to fix non-attendance; reminders and cost or transport support may matter more.

-- ============================================
-- 8. Data Limitations
-- ============================================
-- 1. Dates were supplied as dd-mm-yy text. An initial import misread them and produced a false 43.2% "invalid sequence" rate. After converting
--    with STR_TO_DATE(..., '%d-%m-%y'), 0 records have an appointment before its scheduled date.
-- 2. 285 records, all with an appointment date of 2025-12-31, have a stored lead time that does not match their dates, and 304 appointments fall on
--    that date against 10 to 17 on adjacent days. Lead time was recalculated from the dates, and trend analysis should exclude or annotate
--    2025-12-31. January 2024 is also a partial month (data starts on 5 January).
-- 3. Wait time was stored as 0 instead of NULL for the 2,184 appointments that did not take place. These values were set to NULL so that
--    wait time applies to completed appointments only.
-- 4. Patient_Type is recorded per appointment, not from patient history (1,636 patients are flagged "New Patient" more than once), so
--    new versus returning comparisons are made at appointment level.
-- 5. The dataset contains one city per state, so geographic analysis at city level adds no detail beyond state level.

-- ============================================
-- 9. Recommendations
-- ============================================
-- 1. Develop a broader strategy for reducing missed appointments
-- Since no-shows and cancellations account for a meaningful portion of scheduled appointments, the hospital should evaluate interventions across
-- departments rather than focusing on a single specialty.
-- Potential areas include appointment reminders, easier rescheduling, flexible appointment options, and clearer communication before appointments.
-- The specific intervention should be tested against actual attendance outcomes rather than assumed to be effective.

-- 2. Improve the capture of no-show and cancellation reasons
-- The 17.2% Unknown no-show category limits the ability to understand why patients miss appointments.
-- The hospital could standardize reason categories and encourage staff to record the reason consistently. Better data capture would allow
-- management to identify the most important drivers and measure whether interventions are working.

-- 3. Investigate hospital-wide waiting-time drivers
-- Because average waiting times were similar across departments (61.4 to 64.6 minutes) and 5.3% of completed visits waited more than two hours,
-- management should investigate broader operational factors such as:
-- . Appointment scheduling density
-- . Staffing capacity
-- . Patient flow
-- . Scheduling buffers
-- . Delays between appointments
-- Dental could be used as a starting point for a pilot because it recorded the highest average wait time.

-- 4. Improve utilization of higher-fee departments
-- Neurology had the highest average consultation fee, but its completed appointment volume was substantially lower than General Medicine.
-- Management could examine appointment capacity, provider availability, and utilization in higher-fee departments to determine whether additional
-- completed appointments could be supported without compromising service quality.

-- 5. Strengthen data quality controls
-- The date, lead-time and wait-time issues found in this dataset show the importance of validation rules in appointment systems.
-- Future data pipelines should include automated checks for:
-- . Consistent date formats (for example, always yyyy-mm-dd)
-- . Lead time calculated from the dates, not stored separately
-- . NULL instead of 0 for fields that do not apply to appointments that did not take place
-- . Unusual concentrations of appointments on a single date
-- . Appointment date before scheduled date
-- . Duplicate appointment IDs
-- This would improve confidence in future operational and financial reporting.
