-- =====================================================================
-- MediCare : Hospital Information and Management Database
-- DBMS Course Project - Team 1
-- File    : schema/create_tables.sql
-- Purpose : Creates the database, all 11 tables, constraints and indexes
-- RDBMS   : MySQL 8.0.16+ (CHECK constraints are only enforced from 8.0.16)
--
-- The script can be re-run any number of times. WARNING: it drops the
-- existing "medicare" database, so all data inside it is deleted.
-- Run order: create_tables.sql -> insert_data.sql -> queries.sql
-- =====================================================================

DROP DATABASE IF EXISTS medicare;
CREATE DATABASE medicare;
USE medicare;

-- Safety net if the database is not dropped above: drop children first,
-- then parents (reverse of the creation order).
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS prescription_medicines;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS medicines;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS diagnoses;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS departments;


-- ---------------------------------------------------------------------
-- 1. DEPARTMENTS
-- ---------------------------------------------------------------------
CREATE TABLE departments (
    department_id  INT PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(100) NOT NULL UNIQUE,
    location       VARCHAR(100)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. DOCTORS  (each doctor belongs to exactly one department)
-- ---------------------------------------------------------------------
CREATE TABLE doctors (
    doctor_id         INT PRIMARY KEY AUTO_INCREMENT,
    name              VARCHAR(100)  NOT NULL,
    specialisation    VARCHAR(100)  NOT NULL,
    consultation_fee  DECIMAL(10,2) NOT NULL,
    department_id     INT           NOT NULL,

    CONSTRAINT fk_doctors_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_doctor_fee CHECK (consultation_fee >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. PATIENTS
-- ---------------------------------------------------------------------
CREATE TABLE patients (
    patient_id   INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    dob          DATE         NOT NULL,
    gender       VARCHAR(20)  NOT NULL,
    phone        VARCHAR(15),
    blood_group  VARCHAR(5),

    CONSTRAINT chk_patient_gender
        CHECK (gender IN ('Male', 'Female', 'Other')),

    CONSTRAINT chk_patient_blood_group
        CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. ROOMS
-- ---------------------------------------------------------------------
CREATE TABLE rooms (
    room_id       INT PRIMARY KEY AUTO_INCREMENT,
    room_type     VARCHAR(50)   NOT NULL,
    daily_charge  DECIMAL(10,2) NOT NULL,
    is_available  BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_room_charge CHECK (daily_charge >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. APPOINTMENTS  (outpatient visit: one patient, one doctor)
-- ---------------------------------------------------------------------
CREATE TABLE appointments (
    appointment_id    INT PRIMARY KEY AUTO_INCREMENT,
    patient_id        INT         NOT NULL,
    doctor_id         INT         NOT NULL,
    appointment_date  DATETIME    NOT NULL,
    status            VARCHAR(20) NOT NULL DEFAULT 'Scheduled',

    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_appointment_status
        CHECK (status IN ('Scheduled', 'Completed', 'Cancelled'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. DIAGNOSES
-- ---------------------------------------------------------------------
CREATE TABLE diagnoses (
    diagnosis_id    INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id  INT  NOT NULL,
    description     TEXT NOT NULL,
    diagnosis_date  DATE NOT NULL,

    CONSTRAINT fk_diagnoses_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. ADMISSIONS  (inpatient stay; discharge_date NULL = still admitted)
-- ---------------------------------------------------------------------
CREATE TABLE admissions (
    admission_id    INT PRIMARY KEY AUTO_INCREMENT,
    patient_id      INT  NOT NULL,
    room_id         INT  NOT NULL,
    admit_date      DATE NOT NULL,
    discharge_date  DATE,

    CONSTRAINT fk_admissions_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_admissions_room
        FOREIGN KEY (room_id) REFERENCES rooms(room_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_admission_dates
        CHECK (discharge_date IS NULL OR discharge_date >= admit_date)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. MEDICINES  (master list)
-- ---------------------------------------------------------------------
CREATE TABLE medicines (
    medicine_id   INT PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(100)  NOT NULL,
    manufacturer  VARCHAR(100),
    unit_price    DECIMAL(10,2) NOT NULL,

    CONSTRAINT chk_medicine_price CHECK (unit_price >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. PRESCRIPTIONS
-- ---------------------------------------------------------------------
CREATE TABLE prescriptions (
    prescription_id  INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id   INT  NOT NULL,
    issued_date      DATE NOT NULL,

    CONSTRAINT fk_prescriptions_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. PRESCRIPTION_MEDICINES  (bridge table for the M:N relationship)
-- ---------------------------------------------------------------------
CREATE TABLE prescription_medicines (
    prescription_id  INT          NOT NULL,
    medicine_id      INT          NOT NULL,
    dosage           VARCHAR(100) NOT NULL,
    duration_days    INT          NOT NULL,

    PRIMARY KEY (prescription_id, medicine_id),

    CONSTRAINT fk_pm_prescription
        FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_pm_medicine
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_pm_duration CHECK (duration_days > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 11. PAYMENTS  (linked to an appointment, an admission, or both)
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      INT PRIMARY KEY AUTO_INCREMENT,
    patient_id      INT           NOT NULL,
    appointment_id  INT           NULL,
    admission_id    INT           NULL,
    amount          DECIMAL(10,2) NOT NULL,
    payment_date    DATE          NOT NULL,
    mode            VARCHAR(20)   NOT NULL,

    CONSTRAINT fk_payments_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_payments_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT fk_payments_admission
        FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount CHECK (amount > 0),

    CONSTRAINT chk_payment_mode
        CHECK (mode IN ('Cash', 'Card', 'UPI', 'Online')),

    CONSTRAINT chk_payment_reference
        CHECK (appointment_id IS NOT NULL OR admission_id IS NOT NULL)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- INDEXES
-- MySQL already indexes every foreign key column automatically, so the
-- indexes below cover the other columns the queries filter or group on.
-- ---------------------------------------------------------------------
CREATE INDEX idx_appointments_date   ON appointments (appointment_date);
CREATE INDEX idx_appointments_status ON appointments (status);
CREATE INDEX idx_admissions_dates    ON admissions (admit_date, discharge_date);
CREATE INDEX idx_payments_date       ON payments (payment_date);
CREATE INDEX idx_patients_name       ON patients (name);
