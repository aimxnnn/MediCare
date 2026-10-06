-- =====================================================================
-- MediCare : Hospital Information and Management Database
-- File    : docs/data_fixes.sql
-- Purpose : Record of data-quality issues found in insert_data.sql and
--           how each was fixed. Kept as a standalone file (rather than
--           folded only into code comments inside insert_data.sql) so
--           it can be read on its own for the report/viva.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. PRESCRIPTIONS LINKED TO THE WRONG APPOINTMENT
-- ---------------------------------------------------------------------
-- Problem:
--   Prescriptions 19-29 used appointment_id 19-29 directly. But the
--   diagnoses table correctly SKIPS appointment 19 (status = Cancelled)
--   and appointment 24 (status = Scheduled) -- you can't diagnose or
--   prescribe for a visit that never happened. So prescription 19
--   pointed at a cancelled appointment, and its issued_date
--   ('2026-04-02') didn't even match appointment 19's date
--   ('2026-03-15').
--
-- Fix:
--   Re-pointed appointment_id for prescriptions 19-29 to the sequence
--   20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31 -- the same sequence
--   diagnoses already uses. issued_date values were already correct
--   for this sequence; only appointment_id was wrong.
--
-- Why it mattered:
--   Under the old mapping, the metformin + insulin prescription
--   (prescription 21) landed on a hypertension follow-up instead of
--   the diabetes follow-up it was written for.
--
-- Verification query (should return 0 rows):
SELECT pr.prescription_id, pr.appointment_id, a.status
FROM prescriptions pr
JOIN appointments a ON a.appointment_id = pr.appointment_id
WHERE a.status != 'Completed';


-- ---------------------------------------------------------------------
-- 2. ROOM DOUBLE-BOOKING
-- ---------------------------------------------------------------------
-- Problem:
--   Admission 9 (patient 4, room 3) was admitted on 2026-01-16 with no
--   discharge_date -- i.e. still occupying room 3 indefinitely -- while
--   admission 3 (patient 9) also used room 3 from 2026-02-11 to
--   2026-02-14. Two patients in the same room at once breaks the
--   project's own rule of one active admission per room.
--
-- Fix:
--   Moved admission 9 from room 3 to room 4 -- same room type
--   (Semi-Private), same daily_charge, and otherwise sitting empty.
--
-- Verification query (should return 0 rows):
SELECT a1.admission_id, a1.room_id, a2.admission_id AS conflicts_with
FROM admissions a1
JOIN admissions a2
  ON a1.room_id = a2.room_id
 AND a1.admission_id < a2.admission_id
 AND a1.admit_date <= COALESCE(a2.discharge_date, '9999-12-31')
 AND a2.admit_date <= COALESCE(a1.discharge_date, '9999-12-31');


-- ---------------------------------------------------------------------
-- 3. rooms.is_available DID NOT MATCH ACTUAL OCCUPANCY
-- ---------------------------------------------------------------------
-- Problem:
--   Rooms 1 and 3 had an open (undischarged) admission but were
--   flagged TRUE (available). Rooms 4 and 7 were flagged FALSE with no
--   admission in them at all.
--
-- Fix:
--   Recalculated directly from the admissions data: a room is FALSE
--   only if it currently has an admission with discharge_date IS NULL.
--   After fix #2: room 1 = FALSE (admission 10 still open), room 4 =
--   FALSE (admission 9 now here), rooms 3 and 7 = TRUE (their
--   admissions have been discharged).
--
-- Verification query (is_available should be FALSE only where
-- open_admissions > 0):
SELECT r.room_id, r.is_available,
       (SELECT COUNT(*) FROM admissions ad
         WHERE ad.room_id = r.room_id AND ad.discharge_date IS NULL) AS open_admissions
FROM rooms r
ORDER BY r.room_id;


-- ---------------------------------------------------------------------
-- 4. ADMISSION PAYMENTS DID NOT MATCH daily_charge x LENGTH OF STAY
-- ---------------------------------------------------------------------
-- Problem:
--   Admission 1: 4 days in ICU at Rs.7500/day should total Rs.30000;
--   the payment on file was Rs.4800.
--   Admission 2: 3 days in a Private room at Rs.3800/day should total
--   Rs.11400; the payment on file was Rs.3800 (one night's rate, not
--   three).
--
-- Fix:
--   Corrected both payments to the calculated total. The other six
--   discharged admissions were checked the same way and were already
--   correct.
--
-- Verification query (expected should equal actual_paid for every row):
SELECT ad.admission_id, r.daily_charge,
       DATEDIFF(ad.discharge_date, ad.admit_date) AS nights,
       r.daily_charge * DATEDIFF(ad.discharge_date, ad.admit_date) AS expected,
       p.amount AS actual_paid
FROM admissions ad
JOIN rooms r ON r.room_id = ad.room_id
JOIN payments p ON p.admission_id = ad.admission_id
WHERE ad.discharge_date IS NOT NULL;


-- ---------------------------------------------------------------------
-- 5. FOUR APPOINTMENTS HAD A DOCTOR INCONSISTENT WITH THEIR DIAGNOSIS
--    AND THEIR PAYMENT AMOUNT
-- ---------------------------------------------------------------------
-- Problem:
--   Appointments 15 and 18 had their doctors swapped: appointment 15
--   (neonatal jaundice) was billed Rs.700 -- Dr. Kulkarni's
--   (Neonatology) fee -- but was assigned to Dr. Menon (Dermatology).
--   Appointment 18 (eczema) was billed Rs.1000 -- Dr. Menon's fee --
--   but was assigned to Dr. Kulkarni.
--   Appointments 5 and 26 (an ankle sprain and a ligament sprain, both
--   Sports Medicine territory) were assigned to Dr. Kulkarni
--   (Neonatology) but billed Rs.800, which is Dr. Shetty's (Sports
--   Medicine) fee.
--
-- Fix:
--   Reassigned each appointment to the doctor its fee and diagnosis
--   actually point to: 15 -> Dr. Kulkarni, 18 -> Dr. Menon,
--   5 and 26 -> Dr. Shetty.
--
-- Why it mattered:
--   This directly skewed Q1 (patients per doctor), Q2 (appointments
--   per department), and Q10 (revenue per doctor) -- all three group by
--   doctor_id.
--
-- Verification query (doctor fee, diagnosis and payment should align):
SELECT a.appointment_id, d.name AS doctor, d.consultation_fee,
       dg.description, p.amount AS payment_amount
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
LEFT JOIN diagnoses dg ON dg.appointment_id = a.appointment_id
LEFT JOIN payments p ON p.appointment_id = a.appointment_id
WHERE a.appointment_id IN (5, 15, 18, 26);


-- ---------------------------------------------------------------------
-- 6. PEDIATRIC / NEONATAL DIAGNOSES ATTACHED TO ADULT PATIENTS
-- ---------------------------------------------------------------------
-- Problem:
--   No patient in the original data was born after 2001, yet three
--   diagnoses were pediatric or neonatal in nature: "Acute bronchitis
--   (pediatric)" and "Pediatric asthma review" (both on patient 8, an
--   adult), and "Neonatal jaundice, mild" (on patient 12, also an
--   adult).
--
-- Fix:
--   Added two patients -- an infant (Baby Reyansh Rao, DOB 2026-01-20)
--   for the neonatal diagnosis, and a child (Tanvi Hegde, DOB
--   2018-05-10) for the two pediatric diagnoses -- and reassigned
--   appointments 9, 15 and 27 to them.
--
-- Side effect (expected, not a bug):
--   Patient 8 no longer has any appointments, so she now correctly
--   appears in Q4's "never visited" list. Doctors 3 and 4 now tie at 4
--   patients each in Q1 -- a legitimate consequence of fix #5, worth
--   being ready to discuss in the viva (e.g. breaking the tie with a
--   secondary ORDER BY key).
--
-- Verification query (every diagnosis here should now show a patient
-- under 18):
SELECT a.appointment_id, pt.name, pt.dob, dg.description
FROM appointments a
JOIN patients pt ON pt.patient_id = a.patient_id
JOIN diagnoses dg ON dg.appointment_id = a.appointment_id
WHERE a.appointment_id IN (9, 15, 27);


-- ---------------------------------------------------------------------
-- SCHEMA NOTE: payments.patient_id was removed
-- ---------------------------------------------------------------------
-- The original schema had payments.patient_id as NOT NULL, but
-- insert_data.sql never populates it -- that combination would fail
-- on load. patient_id on a payment is fully derivable through
-- appointment_id (-> appointments.patient_id) or admission_id
-- (-> admissions.patient_id), so storing it again is a transitive
-- dependency and a 3NF violation, not just a loading bug. The column
-- and its foreign key were removed from schema/create_tables.sql, and
-- a view was added so queries can still resolve the patient easily:
--
--   CREATE OR REPLACE VIEW payments_with_patient AS
--   SELECT pay.payment_id,
--          COALESCE(a.patient_id, ad.patient_id) AS patient_id,
--          pay.appointment_id, pay.admission_id,
--          pay.amount, pay.payment_date, pay.mode
--   FROM payments pay
--   LEFT JOIN appointments a ON a.appointment_id = pay.appointment_id
--   LEFT JOIN admissions ad  ON ad.admission_id = pay.admission_id;
