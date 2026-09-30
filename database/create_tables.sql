
-- MEDICARE - HOSPITAL MANAGEMENT DATABASE
-- DBMS Course Project - Team 1
-- MySQL 8.x
--
-- This script can be run from top to bottom.
-- WARNING: DROP DATABASE deletes the existing medicare database
-- and all data inside it.



-- 1. DROP AND CREATE DATABASE


DROP DATABASE IF EXISTS medicare;
CREATE DATABASE medicare;
USE medicare;



-- 2. CREATE TABLES



-- TABLE 1: DEPARTMENTS

CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100)
);



-- TABLE 2: DOCTORS

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    specialisation VARCHAR(100) NOT NULL,
    consultation_fee DECIMAL(10,2) NOT NULL,
    department_id INT NOT NULL,

    CONSTRAINT fk_doctors_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_doctor_fee
        CHECK (consultation_fee >= 0)
);



-- TABLE 3: PATIENTS

CREATE TABLE patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    phone VARCHAR(15),
    blood_group VARCHAR(5),

    CONSTRAINT chk_patient_gender
        CHECK (gender IN ('Male', 'Female', 'Other')),

    CONSTRAINT chk_patient_blood_group
        CHECK (blood_group IN (
            'A+', 'A-', 'B+', 'B-',
            'AB+', 'AB-', 'O+', 'O-'
        ))
);



-- TABLE 4: ROOMS

CREATE TABLE rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_type VARCHAR(50) NOT NULL,
    daily_charge DECIMAL(10,2) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_room_charge
        CHECK (daily_charge >= 0)
);



-- TABLE 5: APPOINTMENTS

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Scheduled',

    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_appointment_status
        CHECK (status IN ('Scheduled', 'Completed', 'Cancelled'))
);



-- TABLE 6: DIAGNOSES

CREATE TABLE diagnoses (
    diagnosis_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id INT NOT NULL,
    description TEXT NOT NULL,
    diagnosis_date DATE NOT NULL,

    CONSTRAINT fk_diagnoses_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);



-- TABLE 7: ADMISSIONS

CREATE TABLE admissions (
    admission_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    room_id INT NOT NULL,
    admit_date DATE NOT NULL,
    discharge_date DATE,

    CONSTRAINT fk_admissions_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_admissions_room
        FOREIGN KEY (room_id)
        REFERENCES rooms(room_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_admission_dates
        CHECK (
            discharge_date IS NULL
            OR discharge_date >= admit_date
        )
);

-- TABLE 8: MEDICINES

CREATE TABLE medicines (
    medicine_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100),
    unit_price DECIMAL(10,2) NOT NULL,

    CONSTRAINT chk_medicine_price
        CHECK (unit_price >= 0)
);


-- TABLE 9: PRESCRIPTIONS

CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id INT NOT NULL,
    issued_date DATE NOT NULL,

    CONSTRAINT fk_prescriptions_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);



-- TABLE 10: PRESCRIPTION_MEDICINES
-- Bridge table for the M:N relationship between
-- prescriptions and medicines.

CREATE TABLE prescription_medicines (
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    duration_days INT NOT NULL,

    PRIMARY KEY (prescription_id, medicine_id),

    CONSTRAINT fk_pm_prescription
        FOREIGN KEY (prescription_id)
        REFERENCES prescriptions(prescription_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_pm_medicine
        FOREIGN KEY (medicine_id)
        REFERENCES medicines(medicine_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_pm_duration
        CHECK (duration_days > 0)
);



-- PAYMENTS


CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    admission_id INT NULL,
    appointment_id INT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    mode VARCHAR(20) NOT NULL,

    CONSTRAINT fk_payment_admission
        FOREIGN KEY (admission_id)
        REFERENCES admissions(admission_id),

    CONSTRAINT fk_payment_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    CONSTRAINT chk_payment_mode
        CHECK (mode IN ('Cash', 'Card', 'UPI', 'Online')),

    CONSTRAINT chk_payment_reference
        CHECK (
            admission_id IS NOT NULL
            OR appointment_id IS NOT NULL
        )
);



-- 3. DATABASE STRUCTURE CREATED



-- 3. BASIC VERIFICATION QUERIES


-- Show all tables
SHOW TABLES;

-- Check number of rows in each table
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'doctors', COUNT(*) FROM doctors
UNION ALL
SELECT 'patients', COUNT(*) FROM patients
UNION ALL
SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL
SELECT 'diagnoses', COUNT(*) FROM diagnoses
UNION ALL
SELECT 'admissions', COUNT(*) FROM admissions
UNION ALL
SELECT 'medicines', COUNT(*) FROM medicines
UNION ALL
SELECT 'prescriptions', COUNT(*) FROM prescriptions
UNION ALL
SELECT 'prescription_medicines', COUNT(*) FROM prescription_medicines
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;

-- Check the inserted data
SELECT * FROM departments;
SELECT * FROM doctors;
SELECT * FROM patients;
SELECT * FROM rooms;
SELECT * FROM appointments;
SELECT * FROM diagnoses;
SELECT * FROM admissions;
SELECT * FROM medicines;
SELECT * FROM prescriptions;
SELECT * FROM prescription_medicines;
SELECT * FROM payments;





