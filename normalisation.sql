-- ============================================================
-- MediCare: Hospital Information and Management Database
-- Normalised Relational Schema - Up to 3NF
-- RDBMS: MySQL
-- Based on the MediCare Normalisation Document
-- ============================================================

DROP DATABASE IF EXISTS medicare;
CREATE DATABASE medicare;
USE medicare;

-- ============================================================
-- 1. DEPARTMENTS
-- Functional dependency:
-- department_id -> name, location
-- ============================================================
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- ============================================================
-- 2. PATIENTS
-- Functional dependency:
-- patient_id -> name, dob, gender, phone, blood_group
-- ============================================================
CREATE TABLE patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    blood_group VARCHAR(5) NOT NULL
) ENGINE=InnoDB;

-- ============================================================
-- 3. DOCTORS
-- Functional dependency:
-- doctor_id -> name, specialisation, department_id, consultation_fee
-- Department details are stored separately in departments (3NF).
-- ============================================================
CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    specialisation VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,
    consultation_fee DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_doctors_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 4. APPOINTMENTS
-- Functional dependency:
-- appointment_id -> patient_id, doctor_id, appointment_date, status
-- Patient and doctor descriptive data are not repeated here.
-- ============================================================
CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL,

    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 5. ROOMS
-- Functional dependency:
-- room_id -> room_type, daily_charge, is_available
-- ============================================================
CREATE TABLE rooms (
    room_id INT PRIMARY KEY AUTO_INCREMENT,
    room_type VARCHAR(50) NOT NULL,
    daily_charge DECIMAL(10,2) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ============================================================
-- 6. ADMISSIONS
-- Functional dependency:
-- admission_id -> patient_id, room_id, admit_date, discharge_date
-- Room details remain in rooms (3NF).
-- ============================================================
CREATE TABLE admissions (
    admission_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    room_id INT NOT NULL,
    admit_date DATE NOT NULL,
    discharge_date DATE NULL,

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
        CHECK (discharge_date IS NULL OR discharge_date >= admit_date)
) ENGINE=InnoDB;

-- ============================================================
-- 7. DIAGNOSES
-- Functional dependency:
-- diagnosis_id -> appointment_id, description, diagnosis_date
-- ============================================================
CREATE TABLE diagnoses (
    diagnosis_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    diagnosis_date DATE NOT NULL,

    CONSTRAINT fk_diagnoses_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 8. PRESCRIPTIONS
-- Functional dependency:
-- prescription_id -> appointment_id, issued_date
-- ============================================================
CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id INT NOT NULL,
    issued_date DATE NOT NULL,

    CONSTRAINT fk_prescriptions_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 9. MEDICINES
-- Functional dependency:
-- medicine_id -> name, manufacturer, unit_price
-- ============================================================
CREATE TABLE medicines (
    medicine_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

-- ============================================================
-- 10. PRESCRIPTION_MEDICINES
-- Composite primary key:
-- (prescription_id, medicine_id) -> dosage, duration_days
-- This resolves the M:N relationship between prescriptions
-- and medicines and satisfies the 2NF/3NF design.
-- ============================================================
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

    CONSTRAINT chk_duration_days
        CHECK (duration_days > 0)
) ENGINE=InnoDB;

-- ============================================================
-- 11. PAYMENTS
-- Functional dependency:
-- payment_id -> patient_id, appointment_id, admission_id,
--                amount, payment_date, mode
-- appointment_id and admission_id are nullable because a payment
-- may be related to an appointment or an admission.
-- ============================================================
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    appointment_id INT NULL,
    admission_id INT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    mode VARCHAR(20) NOT NULL,

    CONSTRAINT fk_payments_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_payments_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    CONSTRAINT fk_payments_admission
        FOREIGN KEY (admission_id)
        REFERENCES admissions(admission_id),

    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_payment_reference
        CHECK (appointment_id IS NOT NULL OR admission_id IS NOT NULL)
) ENGINE=InnoDB;

-- ============================================================
-- FINAL TABLE LIST
-- 1. departments
-- 2. doctors
-- 3. patients
-- 4. appointments
-- 5. rooms
-- 6. admissions
-- 7. diagnoses
-- 8. prescriptions
-- 9. medicines
-- 10. prescription_medicines
-- 11. payments
-- ============================================================

SHOW TABLES;
