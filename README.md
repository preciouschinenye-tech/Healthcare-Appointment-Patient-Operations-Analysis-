# Healthcare-Appointment-Patient-Operations-Analysis-
SQL (MySQL) and Power BI | 10,000 Appointments | January 2024 – December 2025

An end-to-end data analytics project exploring healthcare appointment patterns, patient attendance, operational efficiency and consultation revenue using SQL and Power BI.

The project involved cleaning and validating a synthetic Nigerian healthcare appointments dataset in MySQL, performing exploratory and business-focused analysis, and developing a five-page interactive Power BI dashboard.

**Dataset disclaimer:** This project uses synthetic data created for portfolio and analytical purposes. It contains no real patient information.

## Business Problem

A multi-state healthcare provider wants to better understand its appointment operations, patient attendance patterns and consultation revenue.

The analysis focuses on five key questions:

- How many scheduled appointments result in completed visits, and what are the reasons for missed appointments?
- Which departments experience longer patient waiting times?
- How do appointment outcomes differ between new and returning patient appointments?
- How are consultation revenue, insurance coverage and patient payments distributed?
- Which departments and states contribute most to consultation revenue?

## Dataset Overview

| Item | Details |
|---|---|
| Appointment records | 10,000 |
| Unique patients | 5,123 |
| Analysis period | January 2024 – December 2025 |
| Departments | 8 |
| States | 18 |
| Cities | 18 (one city per state) |
| Currency | Nigerian naira (₦) |

## Tools and Technologies
- **MySQL / MySQL Workbench:** Data loading, cleaning, transformation, validation, exploratory analysis and business queries.
- **Power BI Desktop:** Power Query, data modelling, DAX measures, data visualisation and interactive dashboard development.

## Data Cleaning and Quality Checks

Several data-quality issues were identified and addressed before analysis.

| Issue | Finding | Resolution |
|---|---|---|
| Date format | Dates were stored as text in dd-mm-yy format. Direct interpretation initially produced an incorrect result, flagging 43.2% of records as having appointments before their scheduled dates. | Dates were converted using MySQL `STR_TO_DATE(..., '%d-%m-%y')` into dedicated `DATE` columns. Validation after conversion found no invalid date sequences. |
| Wait-time placeholders | Wait time was recorded as 0 for 2,184 appointments that did not take place, incorrectly lowering the initial average to 49.3 minutes. | Non-applicable wait-time values were changed to `NULL`. Average wait time was recalculated using completed appointments only. |
| Lead-time mismatch | 285 records had stored lead times that did not agree with the difference between their scheduled and appointment dates. | Lead time was recalculated using the cleaned date columns. |
| Date concentration | 304 appointments occurred on 31 December 2025, compared with approximately 10–17 appointments on neighbouring days. | The date was excluded from monthly trend analysis and the anomaly documented. |
| Patient type | 1,636 patients were labelled as "New Patient" more than once. | Patient type was treated as an appointment-level classification rather than a reliable patient-history classification. |
| Financial consistency | Consultation fee should equal insurance-covered amount plus patient payment. | Financial validation identified zero mismatches. |

## Key Findings
### 1. Appointment Attendance

- Out of 10,000 appointments, 7,816 were completed, representing a completion rate of 78.2%.
- No-shows accounted for 871 appointments (8.7%), cancellations for 797 (8.0%), and rescheduled appointments for 516 (5.2%).
- No-show rates were relatively similar across departments. Dermatology recorded the highest rate at 9.3%, while Neurology had the lowest at 7.9%.
- Transportation issues were the most frequently recorded no-show reason (17.6%). Cost concerns were the leading cancellation reason (21.0%).
- No single recorded reason dominated missed appointments.
- No-show rates ranged from 7.9% to 9.6% across scheduling lead-time groups, showing no clear relationship between longer scheduling lead times and missed appointments.
- New and returning patient appointments had similar completion rates: 78.0% and 78.4%, respectively.

### 2. Operational Performance

Completed appointments had an average waiting time of 63.1 minutes.
413 completed appointments (5.3%) involved waiting longer than two hours.
Average waiting times varied by only 3.2 minutes across departments, from Dental (64.6 minutes) to Dermatology (61.4 minutes).
Average consultation duration was 42.6 minutes.

The relatively small differences in departmental waiting-time averages suggest that the issue may require a broader review of scheduling and patient-flow processes rather than focusing on one department alone.

### 3. Financial and Geographic Performance

- Completed appointments generated approximately ₦237.27 million in consultation revenue.
- Insurance covered approximately ₦109.69 million (46.2%), while patients paid approximately ₦127.58 million (53.8%).
- Self-pay and uninsured appointment categories accounted for approximately ₦72.5 million in patient payments.
- General Medicine generated the highest consultation revenue at approximately ₦36.8 million, despite having the lowest average consultation fee of approximately ₦20,026. This suggests that appointment volume contributed significantly to its total revenue.
- Neurology recorded the highest average consultation fee at approximately ₦46,035.
- Recorded consultation revenue increased from ₦110.62 million in 2024 to ₦126.65 million in 2025, an observed increase of approximately 14.5%.
- Revenue was relatively evenly distributed across the 18 states, ranging from approximately ₦11.9 million to ₦14.4 million. Kwara recorded the highest revenue.

**Revenue comparison caveat:** The 2025 data contains an unusual concentration of appointments on 31 December. The observed annual revenue increase should therefore be interpreted cautiously until the underlying date anomaly is investigated.

## Power BI Dashboard

The interactive report contains five pages, each with dedicated KPI cards, analytical visuals and filtering options.

### 1. Executive Overview

Provides a high-level summary of healthcare performance, including:

- Total appointments
- Total consultation revenue
- Completion rate
- No-show rate
- Average waiting time
- Appointment outcome distribution
- Monthly appointment trends
- Department-level performance

### 2. Appointment Analysis

Explores appointment attendance and missed appointments through:

- No-show and cancellation reasons
- No-show rates by department
- Scheduling lead-time groups
- Appointment-type analysis
- Appointment outcome comparisons

### 3. Patient Analysis

Examines patient demographics and appointment patterns through:

- Age-group distribution
- Gender distribution
- New and returning patient appointments
- Appointment outcomes by patient type
- Insurance-type distribution

### 4. Operational Performance

Evaluates operational efficiency through:

- Average waiting time by department
- Distribution of completed appointments by waiting-time group
- Appointments waiting longer than 120 minutes
- Average consultation duration by department
- Department-level operational summary

### 5. Financial & Geographic Analysis

Explores consultation revenue and payment patterns through:

- Average consultation fees by department
- Insurance coverage versus patient payments
- Revenue by state
- Annual consultation revenue comparison

## Data Modelling and DAX

The Power BI report includes:

- A dedicated date table related to the cleaned appointment date.
- A separate _Measures table to organise DAX measures.
- Measures for appointment counts, completion rate, no-show rate, cancellation rate, waiting time, consultation duration and financial performance.
- Consistent appointment-status colours across all five report pages.
- A monthly appointment trend that excludes the anomalous 31 December 2025 records.

## Recommendations

Based on the findings, the following actions could be considered by the healthcare provider:

- **Improve appointment attendance:** Introduce or evaluate appointment reminders, easier rescheduling options and flexible scheduling to reduce missed appointments.
- **Improve reason tracking:** Review how no-show reasons are captured, particularly because 17.2% of no-show records were classified as "Unknown".
- **Investigate patient waiting times:** Review scheduling density, staffing levels and patient-flow processes across departments. Use departments with relatively high waiting times as starting points for further investigation.
- **Review departmental revenue patterns:** Examine demand, service mix, pricing and available capacity in higher-fee departments such as Neurology to better understand their revenue contribution.
- **Strengthen data quality controls:** Standardise date formats, use NULL for non-applicable values, calculate lead times from validated dates and introduce checks for unusual appointment-date concentrations.

## Project Limitations

- **Synthetic dataset:** The patterns and findings reflect a generated dataset and should not be interpreted as evidence of actual hospital performance or patient behaviour.
- **Geographic coverage:** The dataset contains one city per state, limiting the additional value of city-level comparisons.
- **Partial first month:** January 2024 begins on 5 January and is not a complete month.
- **Date anomaly:** The unusual concentration of appointments on 31 December 2025 may affect daily and monthly trend 
interpretation.
- **No cost data:** The analysis focuses on consultation revenue and payment sources. Operating costs were not available, so profitability could not be assessed.
- **Patient classification:** New and returning patient labels are recorded per appointment and may not consistently represent a patient's actual history.

## Repository Contents

| File / Folder | Description |
|---|---|
| `Healthcare_Appointment_SQL-Analysis.sql` | SQL script covering database setup, data cleaning, validation, exploratory analysis and business questions. |
| `healthcare_appointments.csv` | Synthetic healthcare appointment dataset. |
| `Healthcare_Appointment_Dashboard.pbix` | Interactive five-page Power BI report. |
| `images/` | Exported dashboard screenshots. |

## Author

Precious Chinenye Onyedum
Data & Business Intelligence Analyst
Lagos, Nigeria
