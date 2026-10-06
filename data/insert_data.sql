-- =====================================================================
-- MediCare : Hospital Information and Management Database
-- File    : data/insert_data.sql
-- Purpose : Sample data for all 11 tables
-- RDBMS   : MySQL 8.0+
-- Run after: schema/create_tables.sql
--
-- CHANGELOG (fixes applied after cross-checking the data for internal
-- consistency -- see docs/data_fixes.sql for the full reasoning):
--   1. Prescriptions 19-29 were linked to the wrong appointment_id
--      (sequential 19..29 instead of skipping the Cancelled/Scheduled
--      appointments 19 and 24, as the diagnoses table correctly does).
--   2. Admission 9 was double-booking room 3 against admission 3;
--      moved to room 4, which matches its Semi-Private rate.
--   3. rooms.is_available corrected for rooms 1 and 7 to reflect which
--      rooms actually have a still-open admission.
--   4. Payments for admission 1 and admission 2 recalculated from
--      (room.daily_charge x length of stay) -- they didn't match.
--   5. Appointments 5, 15, 18 and 26 had doctors inconsistent with
--      their diagnosis and with the consultation fee on their payment;
--      corrected to the doctor the fee and diagnosis actually point to.
--   6. Two child patients added; the pediatric/neonatal diagnoses on
--      appointments 9, 15 and 27 were previously attached to adult
--      patients, which doesn't make clinical sense.
-- =====================================================================

USE medicare;


-- 1. DEPARTMENTS

INSERT INTO departments (name, location) VALUES
('Cardiology',       'Block A, 2nd Floor'),
('Orthopedics',      'Block B, 1st Floor'),
('Pediatrics',       'Block A, Ground Floor'),
('General Medicine', 'Block C, 1st Floor'),
('Dermatology',      'Block B, 2nd Floor');


-- 2. DOCTORS

INSERT INTO doctors
(name, specialisation, consultation_fee, department_id)
VALUES
('Dr. Rohan Mehta',     'Interventional Cardiology', 1200.00, 1),
('Dr. Kavita Rao',      'Cardiac Electrophysiology', 1500.00, 1),
('Dr. Suresh Iyer',     'Joint Replacement',          900.00, 2),
('Dr. Nithya Shetty',   'Sports Medicine',            800.00, 2),
('Dr. Ananya Kulkarni', 'Neonatology',                700.00, 3),
('Dr. Farhan Sheikh',   'Pediatric Care',             650.00, 3),
('Dr. Meera Nair',      'Internal Medicine',          600.00, 4),
('Dr. Vikram Desai',    'Internal Medicine',          550.00, 4),
('Dr. Priya Menon',     'Cosmetic Dermatology',      1000.00, 5);


-- 3. PATIENTS
-- Patients 19 and 20 are new (see fix #6): an infant and a child, so the
-- pediatric/neonatal diagnoses attached to appointments 9, 15 and 27
-- are no longer assigned to adult patients.

INSERT INTO patients
(name, dob, gender, phone, blood_group)
VALUES
('Arjun Reddy',       '1990-03-12', 'Male',   '9900001001', 'B+'),
('Sneha Kulkarni',    '1985-07-22', 'Female', '9900001002', 'O+'),
('Manoj Pillai',      '1978-11-02', 'Male',   '9900001003', 'A+'),
('Divya Sharma',      '1995-05-18', 'Female', '9900001004', 'AB+'),
('Rahul Verma',       '2001-09-09', 'Male',   '9900001005', 'O-'),
('Ayesha Khan',       '1988-02-27', 'Female', '9900001006', 'B-'),
('Karthik Subramani', '1999-12-01', 'Male',   '9900001007', 'A-'),
('Neha Joshi',        '1992-08-14', 'Female', '9900001008', 'O+'),
('Amit Bansal',       '1975-04-30', 'Male',   '9900001009', 'B+'),
('Pooja Reddy',       '1983-06-19', 'Female', '9900001010', 'AB-'),
('Vivek Nambiar',     '1970-01-25', 'Male',   '9900001011', 'A+'),
('Shreya Agarwal',    '1993-10-05', 'Female', '9900001012', 'O+'),
('Ibrahim Sait',      '1965-03-08', 'Male',   '9900001013', 'B+'),
('Lakshmi Venkatesh', '1980-07-15', 'Female', '9900001014', 'O-'),
('Ramesh Chandran',   '1991-11-11', 'Male',   '9900001015', 'A+'),
('Fatima Ansari',     '1987-05-05', 'Female', '9900001016', 'B-'),
('Sanjay Gowda',      '1996-09-23', 'Male',   '9900001017', 'O+'),
('Rekha Iyengar',     '1982-12-30', 'Female', '9900001018', 'AB+'),
('Baby Reyansh Rao',  '2026-01-20', 'Male',   '9900001019', 'O+'),
('Tanvi Hegde',       '2018-05-10', 'Female', '9900001020', 'A+');


-- 4. ROOMS
-- is_available corrected (fix #3): room 1 now FALSE (admission 10 is
-- still open there), room 7 now TRUE (its only admission was discharged
-- back in January). Room 3 and room 4 are already correct once
-- admission 9 is moved off room 3 below (fix #2).

INSERT INTO rooms
(room_type, daily_charge, is_available)
VALUES
('General',       1200.00, FALSE),  -- room 1: occupied by admission 10
('General',       1200.00, TRUE),
('Semi-Private',  2200.00, TRUE),
('Semi-Private',  2200.00, FALSE),  -- room 4: occupied by admission 9 (moved here)
('Private',       3800.00, TRUE),
('Private',       3800.00, TRUE),
('ICU',           7500.00, TRUE),   -- room 7: its one admission was discharged
('ICU',           7500.00, TRUE);


-- 5. MEDICINES

INSERT INTO medicines
(name, manufacturer, unit_price)
VALUES
('Paracetamol 500mg',  'Cipla',      12.00),
('Amoxicillin 250mg',  'Sun Pharma', 45.00),
('Atorvastatin 10mg',  'Dr Reddys',  68.00),
('Metformin 500mg',    'Sun Pharma', 30.00),
('Amlodipine 5mg',     'Cipla',      25.00),
('Cetirizine 10mg',    'Mankind',    15.00),
('Azithromycin 500mg', 'Alkem',      90.00),
('Pantoprazole 40mg',  'Dr Reddys',  40.00),
('Ibuprofen 400mg',    'Cipla',      20.00),
('Vitamin D3 60K',      'Mankind',    55.00),
('Salbutamol Inhaler', 'Cipla',      150.00),
('Insulin Glargine',   'Sanofi',     450.00);


-- 6. APPOINTMENTS
-- Doctor corrections (fix #5): appointment 5 and 26 (sprain/ligament
-- diagnoses, 800 fee) now use doctor 4 (Sports Medicine) instead of
-- doctor 5 (Neonatology). Appointments 15 and 18 had their doctors
-- swapped back to match their diagnosis and the fee on their payment:
-- 15 (neonatal jaundice, 700 fee) -> doctor 5; 18 (eczema, 1000 fee) -> doctor 9.
-- Patient corrections (fix #6): appointment 9 and 27 (pediatric
-- diagnoses) now use the new child patient 20 instead of adult patient 8;
-- appointment 15 (neonatal diagnosis) now uses the new infant patient 19
-- instead of adult patient 12.

INSERT INTO appointments
(patient_id, doctor_id, appointment_date, status)
VALUES
(1,  1, '2026-01-10 09:00:00', 'Completed'),
(2,  7, '2026-01-11 10:30:00', 'Completed'),
(3,  3, '2026-01-14 11:00:00', 'Completed'),
(4,  9, '2026-01-15 09:30:00', 'Completed'),
(5,  4, '2026-01-18 12:00:00', 'Completed'),                 -- fix #5: doctor 5 -> 4

(1,  1, '2026-02-02 09:00:00', 'Completed'),
(6,  8, '2026-02-03 10:00:00', 'Completed'),
(7,  3, '2026-02-05 11:30:00', 'Completed'),
(20, 6, '2026-02-07 09:00:00', 'Completed'),                 -- fix #6: patient 8 -> 20
(9,  2, '2026-02-10 15:00:00', 'Completed'),
(2,  7, '2026-02-12 10:00:00', 'Completed'),
(10, 4, '2026-02-15 14:00:00', 'Completed'),

(1,  1, '2026-03-01 09:00:00', 'Completed'),
(11, 3, '2026-03-04 11:00:00', 'Completed'),
(19, 5, '2026-03-06 09:30:00', 'Completed'),                 -- fix #6: patient 12 -> 19
(3,  3, '2026-03-08 11:00:00', 'Completed'),
(13, 7, '2026-03-10 10:00:00', 'Completed'),
(14, 9, '2026-03-13 12:30:00', 'Completed'),                 -- fix #5: doctor 5 -> 9
(4,  9, '2026-03-15 09:30:00', 'Cancelled'),

(9,  2, '2026-04-02 15:00:00', 'Completed'),
(1,  1, '2026-04-05 09:00:00', 'Completed'),
(6,  8, '2026-04-08 10:00:00', 'Completed'),
(7,  4, '2026-04-10 11:00:00', 'Completed'),
(2,  7, '2026-04-12 10:30:00', 'Scheduled'),

(11, 3, '2026-05-02 11:00:00', 'Completed'),
(12, 4, '2026-05-05 09:30:00', 'Completed'),                 -- fix #5: doctor 5 -> 4
(20, 6, '2026-05-08 09:00:00', 'Completed'),                 -- fix #6: patient 8 -> 20
(9,  2, '2026-05-11 15:00:00', 'Completed'),
(1,  1, '2026-05-14 09:00:00', 'Completed'),

(13, 8, '2026-06-01 10:00:00', 'Completed'),
(14, 3, '2026-06-04 11:30:00', 'Completed'),
(1,  2, '2026-06-10 15:00:00', 'Scheduled');


-- 7. ADMISSIONS
-- fix #2: admission 9 moved from room 3 to room 4, resolving the
-- double-booking against admission 3 (which uses room 3, Feb 11-14,
-- while admission 9 has been open since Jan 16).

INSERT INTO admissions
(patient_id, room_id, admit_date, discharge_date)
VALUES
(1,  7, '2026-01-11', '2026-01-15'),
(1,  5, '2026-04-06', '2026-04-09'),
(9,  3, '2026-02-11', '2026-02-14'),
(9,  6, '2026-05-12', '2026-05-16'),
(3,  1, '2026-01-15', '2026-01-17'),
(6,  2, '2026-02-08', '2026-02-10'),
(11, 6, '2026-03-05', '2026-03-08'),
(13, 8, '2026-03-11', '2026-03-14'),
(4,  4, '2026-01-16', NULL),        -- fix #2: room 3 -> 4
(14, 1, '2026-06-05', NULL);


-- 8. DIAGNOSES
-- Unchanged: diagnoses are keyed to appointment_id, not patient_id, so
-- the patient/doctor corrections above don't require any changes here.

INSERT INTO diagnoses
(appointment_id, description, diagnosis_date)
VALUES
(1,  'Hypertension, stage 1',             '2026-01-10'),
(2,  'Seasonal viral fever',              '2026-01-11'),
(3,  'Osteoarthritis, right knee',        '2026-01-14'),
(4,  'Mild acne, contact dermatitis',     '2026-01-15'),
(5,  'Ankle sprain, grade 1',             '2026-01-18'),
(6,  'Angina, stable',                    '2026-02-02'),
(7,  'Type 2 diabetes, newly diagnosed',  '2026-02-03'),
(8,  'Ligament strain',                   '2026-02-05'),
(9,  'Acute bronchitis (pediatric)',      '2026-02-07'),
(10, 'Arrhythmia under evaluation',       '2026-02-10'),
(11, 'Recurrent seasonal fever',          '2026-02-12'),
(12, 'Fracture, wrist (hairline)',        '2026-02-15'),
(13, 'Hypertension follow-up',            '2026-03-01'),
(14, 'Post-op knee review',               '2026-03-04'),
(15, 'Neonatal jaundice, mild',           '2026-03-06'),
(16, 'Osteoarthritis follow-up',          '2026-03-08'),
(17, 'Upper respiratory infection',       '2026-03-10'),
(18, 'Eczema flare-up',                   '2026-03-13'),
(20, 'Angina, stable - review',           '2026-04-02'),
(21, 'Hypertension, controlled',          '2026-04-05'),
(22, 'Type 2 diabetes follow-up',         '2026-04-08'),
(23, 'Sports injury, shoulder',           '2026-04-10'),
(25, 'Knee replacement follow-up',        '2026-05-02'),
(26, 'Sprained ligament, follow-up',      '2026-05-05'),
(27, 'Pediatric asthma review',           '2026-05-08'),
(28, 'Palpitations, monitoring',          '2026-05-11'),
(29, 'Hypertension, routine check',       '2026-05-14'),
(30, 'Diabetic foot check',               '2026-06-01'),
(31, 'Joint pain, chronic review',        '2026-06-04');


-- 9. PRESCRIPTIONS
-- fix #1: prescriptions 19-29 now point at appointment_id 20, 21, 22,
-- 23, 25, 26, 27, 28, 29, 30, 31 -- the same sequence the diagnoses
-- table uses (skipping the Cancelled appointment 19 and the Scheduled
-- appointment 24). issued_date values were already correct; only
-- appointment_id was wrong.

INSERT INTO prescriptions
(appointment_id, issued_date)
VALUES
(1,  '2026-01-10'),
(2,  '2026-01-11'),
(3,  '2026-01-14'),
(4,  '2026-01-15'),
(5,  '2026-01-18'),
(6,  '2026-02-02'),
(7,  '2026-02-03'),
(8,  '2026-02-05'),
(9,  '2026-02-07'),
(10, '2026-02-10'),
(11, '2026-02-12'),
(12, '2026-02-15'),
(13, '2026-03-01'),
(14, '2026-03-04'),
(15, '2026-03-06'),
(16, '2026-03-08'),
(17, '2026-03-10'),
(18, '2026-03-13'),
(20, '2026-04-02'),   -- fix #1: was 19
(21, '2026-04-05'),   -- fix #1: was 20
(22, '2026-04-08'),   -- fix #1: was 21
(23, '2026-04-10'),   -- fix #1: was 22
(25, '2026-05-02'),   -- fix #1: was 23
(26, '2026-05-05'),   -- fix #1: was 24
(27, '2026-05-08'),   -- fix #1: was 25
(28, '2026-05-11'),   -- fix #1: was 26
(29, '2026-05-14'),   -- fix #1: was 27
(30, '2026-06-01'),   -- fix #1: was 28
(31, '2026-06-04');   -- fix #1: was 29


-- 10. PRESCRIPTION_MEDICINES
-- Unchanged: these rows reference prescription_id (1-29), which did not
-- change -- only which appointment each prescription_id pointed to
-- changed above.

INSERT INTO prescription_medicines
(prescription_id, medicine_id, dosage, duration_days)
VALUES
(1,  5,  '1 tablet OD', 30),
(1,  1,  '1 tablet SOS', 5),

(2,  1,  '1 tablet BD', 5),
(2,  6,  '1 tablet OD', 5),

(3,  9,  '1 tablet BD', 10),
(3,  1,  '1 tablet SOS', 7),

(4,  6,  '1 tablet OD', 7),

(5,  9,  '1 tablet BD', 7),

(6,  5,  '1 tablet OD', 30),
(6,  3,  '1 tablet HS', 30),

(7,  4,  '1 tablet BD', 60),

(8,  9,  '1 tablet BD', 5),

(9,  7,  '1 tablet OD', 5),
(9,  1,  '1 tablet SOS', 3),

(10, 5,  '1 tablet OD', 30),

(11, 1,  '1 tablet SOS', 5),
(11, 6,  '1 tablet OD', 5),

(12, 9,  '1 tablet BD', 10),

(13, 5,  '1 tablet OD', 30),

(14, 9,  '1 tablet BD', 10),

(15, 10, '5 drops OD', 30),

(16, 9,  '1 tablet BD', 10),

(17, 1,  '1 tablet SOS', 5),
(17, 8,  '1 tablet OD', 14),

(18, 6,  '1 tablet OD', 10),

(19, 5,  '1 tablet OD', 30),
(19, 3,  '1 tablet HS', 30),

(20, 5,  '1 tablet OD', 30),

(21, 4,  '1 tablet BD', 60),
(21, 12, '10 units OD', 90),

(22, 9,  '1 tablet BD', 7),

(23, 9,  '1 tablet SOS', 10),

(24, 9,  '1 tablet BD', 7),

(25, 11, '2 puffs BD', 30),

(26, 5,  '1 tablet OD', 30),

(27, 5,  '1 tablet OD', 30),

(28, 12, '10 units OD', 90),
(28, 4,  '1 tablet BD', 60),

(29, 3,  '1 tablet HS', 30);


-- 11. PAYMENTS
-- patient_id is not stored here (see schema note) -- use the
-- payments_with_patient view, or join through appointments/admissions,
-- whenever a query needs the patient behind a payment.
-- fix #4: admission 1's payment corrected from 4800 to 30000
-- (4 days in ICU @ 7500/day). admission 2's payment corrected from
-- 3800 to 11400 (3 days in a Private room @ 3800/day).

INSERT INTO payments
(appointment_id, admission_id, amount, payment_date, mode)
VALUES
(1,  NULL, 1200.00,  '2026-01-10', 'UPI'),
(NULL, 1,  30000.00, '2026-01-15', 'Card'),   -- fix #4: was 4800.00

(2,  NULL, 600.00,   '2026-01-11', 'Cash'),

(3,  NULL, 900.00,   '2026-01-14', 'UPI'),
(NULL, 5,  2400.00,  '2026-01-17', 'Card'),

(4,  NULL, 1000.00,  '2026-01-15', 'Cash'),

(5,  NULL, 800.00,   '2026-01-18', 'UPI'),

(6,  NULL, 1200.00,  '2026-02-02', 'UPI'),

(7,  NULL, 550.00,   '2026-02-03', 'Online'),
(NULL, 6,  2400.00,  '2026-02-10', 'Online'),

(8,  NULL, 900.00,   '2026-02-05', 'Cash'),

(9,  NULL, 650.00,   '2026-02-07', 'UPI'),

(10, NULL, 1500.00,  '2026-02-10', 'Card'),
(NULL, 3,  6600.00,  '2026-02-14', 'Card'),

(11, NULL, 600.00,   '2026-02-12', 'Cash'),

(12, NULL, 800.00,   '2026-02-15', 'UPI'),

(13, NULL, 1200.00,  '2026-03-01', 'UPI'),

(14, NULL, 900.00,   '2026-03-04', 'Cash'),
(NULL, 7,  11400.00, '2026-03-08', 'Online'),

(15, NULL, 700.00,   '2026-03-06', 'UPI'),

(16, NULL, 900.00,   '2026-03-08', 'Cash'),

(17, NULL, 600.00,   '2026-03-10', 'UPI'),
(NULL, 8,  22500.00, '2026-03-14', 'Online'),

(18, NULL, 1000.00,  '2026-03-13', 'Card'),

(20, NULL, 1500.00,  '2026-04-02', 'Card'),

(21, NULL, 1200.00,  '2026-04-05', 'UPI'),
(NULL, 2,  11400.00, '2026-04-09', 'Card'),   -- fix #4: was 3800.00

(22, NULL, 550.00,   '2026-04-08', 'Online'),

(23, NULL, 800.00,   '2026-04-10', 'Cash'),

(25, NULL, 900.00,   '2026-05-02', 'Cash'),

(26, NULL, 800.00,   '2026-05-05', 'UPI'),

(27, NULL, 650.00,   '2026-05-08', 'UPI'),

(28, NULL, 1500.00,  '2026-05-11', 'Card'),
(NULL, 4,  15200.00, '2026-05-16', 'Online'),

(29, NULL, 1200.00,  '2026-05-14', 'UPI'),

(30, NULL, 550.00,   '2026-06-01', 'Cash'),

(31, NULL, 900.00,   '2026-06-04', 'UPI');


-- =========================================
-- VERIFICATION
-- =========================================

USE medicare;

SHOW TABLES;

SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL SELECT 'doctors', COUNT(*) FROM doctors
UNION ALL SELECT 'patients', COUNT(*) FROM patients
UNION ALL SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL SELECT 'diagnoses', COUNT(*) FROM diagnoses
UNION ALL SELECT 'admissions', COUNT(*) FROM admissions
UNION ALL SELECT 'medicines', COUNT(*) FROM medicines
UNION ALL SELECT 'prescriptions', COUNT(*) FROM prescriptions
UNION ALL SELECT 'prescription_medicines', COUNT(*) FROM prescription_medicines
UNION ALL SELECT 'payments', COUNT(*) FROM payments;

-- Check the payment view
SELECT * FROM payments_with_patient;
