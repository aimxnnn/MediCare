-- =====================================================================
-- MediCare : Hospital Information and Management Database
-- File    : queries/queries.sql
-- Purpose : Business questions Q1-Q7 (required) and Q8-Q11 (team's own)
-- RDBMS   : MySQL 8.0+
-- Run after: schema/create_tables.sql, data/insert_data.sql
-- =====================================================================

USE medicare;

-- ---------------------------------------------------------------------
-- Q1: Which doctors have treated the most patients?
-- (distinct patients per doctor, across completed + scheduled visits)
-- ---------------------------------------------------------------------
SELECT d.doctor_id,
       d.name                              AS doctor_name,
       dept.name                           AS department,
       COUNT(DISTINCT a.patient_id)        AS patients_treated
FROM doctors d
JOIN departments dept ON dept.department_id = d.department_id
JOIN appointments a   ON a.doctor_id = d.doctor_id
GROUP BY d.doctor_id, d.name, dept.name
ORDER BY patients_treated DESC;


-- ---------------------------------------------------------------------
-- Q2: Which department has the most appointments?
-- ---------------------------------------------------------------------
SELECT dept.department_id,
       dept.name              AS department,
       COUNT(a.appointment_id) AS total_appointments
FROM departments dept
JOIN doctors d       ON d.department_id = dept.department_id
JOIN appointments a  ON a.doctor_id = d.doctor_id
GROUP BY dept.department_id, dept.name
ORDER BY total_appointments DESC
LIMIT 1;


-- ---------------------------------------------------------------------
-- Q3: What is the average consultation fee by department?
-- ---------------------------------------------------------------------
SELECT dept.name                       AS department,
       COUNT(d.doctor_id)              AS num_doctors,
       ROUND(AVG(d.consultation_fee),2) AS avg_consultation_fee
FROM departments dept
JOIN doctors d ON d.department_id = dept.department_id
GROUP BY dept.department_id, dept.name
ORDER BY avg_consultation_fee DESC;


-- ---------------------------------------------------------------------
-- Q4: Which registered patients have never visited the hospital?
-- (no row at all in appointments)
-- ---------------------------------------------------------------------
SELECT p.patient_id, p.name, p.phone
FROM patients p
LEFT JOIN appointments a ON a.patient_id = p.patient_id
WHERE a.appointment_id IS NULL
ORDER BY p.patient_id;


-- ---------------------------------------------------------------------
-- Q5: Which medicines are prescribed most frequently?
-- (counted by number of prescriptions they appear in)
-- ---------------------------------------------------------------------
SELECT m.medicine_id,
       m.name                       AS medicine_name,
       COUNT(pm.prescription_id)    AS times_prescribed
FROM medicines m
JOIN prescription_medicines pm ON pm.medicine_id = m.medicine_id
GROUP BY m.medicine_id, m.name
ORDER BY times_prescribed DESC;


-- ---------------------------------------------------------------------
-- Q6: Which patients have been admitted more than once?
-- ---------------------------------------------------------------------
SELECT p.patient_id, p.name, COUNT(ad.admission_id) AS total_admissions
FROM patients p
JOIN admissions ad ON ad.patient_id = p.patient_id
GROUP BY p.patient_id, p.name
HAVING COUNT(ad.admission_id) > 1
ORDER BY total_admissions DESC;


-- ---------------------------------------------------------------------
-- Q7: What is the hospital's revenue over time (monthly)?
-- ---------------------------------------------------------------------
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS revenue_month,
       COUNT(*)                          AS num_payments,
       SUM(amount)                       AS total_revenue
FROM payments
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY revenue_month;


-- =======================================================================
-- The team's own additional questions (Q8-Q11)
-- =======================================================================

-- ---------------------------------------------------------------------
-- Q8: Room occupancy - how many times has each room been used, and
-- what type of room is it? (helps flag high-demand room types)
-- ---------------------------------------------------------------------
SELECT r.room_id,
       r.room_type,
       r.is_available,
       COUNT(ad.admission_id) AS times_used
FROM rooms r
LEFT JOIN admissions ad ON ad.room_id = r.room_id
GROUP BY r.room_id, r.room_type, r.is_available
ORDER BY times_used DESC;


-- ---------------------------------------------------------------------
-- Q9: Average length of stay (in days) per room type, for admissions
-- that have already been discharged.
-- ---------------------------------------------------------------------
SELECT r.room_type,
       ROUND(AVG(DATEDIFF(ad.discharge_date, ad.admit_date)), 1) AS avg_stay_days,
       COUNT(*)                                                  AS discharged_admissions
FROM admissions ad
JOIN rooms r ON r.room_id = ad.room_id
WHERE ad.discharge_date IS NOT NULL
GROUP BY r.room_type
ORDER BY avg_stay_days DESC;


-- ---------------------------------------------------------------------
-- Q10: Consultation revenue generated by each doctor
-- (based on their consultation fee x number of completed appointments)
-- ---------------------------------------------------------------------
SELECT d.doctor_id,
       d.name                                   AS doctor_name,
       d.consultation_fee,
       COUNT(a.appointment_id)                  AS completed_appointments,
       d.consultation_fee * COUNT(a.appointment_id) AS estimated_revenue
FROM doctors d
JOIN appointments a ON a.doctor_id = d.doctor_id AND a.status = 'Completed'
GROUP BY d.doctor_id, d.name, d.consultation_fee
ORDER BY estimated_revenue DESC;


-- ---------------------------------------------------------------------
-- Q11: Appointment cancellation rate per department
-- ---------------------------------------------------------------------
SELECT dept.name AS department,
       COUNT(*)                                              AS total_appointments,
       SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
       ROUND(100.0 * SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                   AS cancellation_rate_pct
FROM appointments a
JOIN doctors d       ON d.doctor_id = a.doctor_id
JOIN departments dept ON dept.department_id = d.department_id
GROUP BY dept.department_id, dept.name
ORDER BY cancellation_rate_pct DESC;
