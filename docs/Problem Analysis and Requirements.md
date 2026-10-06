# MediCare – Hospital Management Database
## Problem Understanding & Requirement Analysis

| Field | Detail |
|---|---|
| **Project Name** | MediCare: Hospital Information and Management Database |
| **Course Component** | Problem Understanding & Requirement Analysis |
| **Team** | Team 1 |
| **Team Size** | 6 members |
| **Target Database** | MySQL |
| **Document Path** | `docs/Problem Analysis and Requirements.md` |

---

## 1. Problem Statement

Every day, hospitals deal with a huge stream of information—patient registrations, doctor schedules, room assignments, prescriptions, and payments. 

In many small and mid-sized healthcare facilities, these records end up scattered across paper files, logbooks, or separate spreadsheets managed by different desks. When data lives in silos, simple daily operations get chaotic fast. Front-desk staff end up re-registering existing patients under duplicate records, rooms get double-booked, medical history gets misplaced across folders, and billing records fail to match the actual care provided.

**MediCare** is designed to fix these exact issues by bringing all hospital records together into a single, centralized database. By giving every team member access to the same reliable, up-to-date information, the system eliminates duplicate work, prevents scheduling mix-ups, and keeps daily operations running smoothly.

---

## 2. Project Objectives

- **One Central Hub:** Bring patient profiles, doctor details, appointments, room bookings, prescriptions, and billing into one connected system.
- **Cleaner Records:** Eliminate duplicate patient profiles and cut down on human data-entry errors.
- **Connected History:** Link diagnoses, prescriptions, and billing charges directly to the right patient and visit.
- **Practical Reporting:** Give hospital administrators a quick way to run SQL queries for revenue, doctor workloads, and room usage.
- **Flexible Base:** Keep the initial database structure clean and simple so new features can easily be added later.

---

## 3. Functional Requirements

The system handles six core areas of hospital operations:

### 3.1 Patient Management & Registration
- Register new patients by storing basic details like full name, date of birth, gender, blood group, phone number, and home address.
- Automatically assign a unique `patient_id` to every new registration.
- Allow staff to look up existing patients before creating a new entry to prevent duplicate profiles.
- Maintain a full history of every visit, admission, diagnosis, and prescription linked to the patient's ID.

### 3.2 Doctor & Department Management
- Maintain a list of hospital departments (such as Cardiology, Pediatrics, or Orthopedics) along with their locations.
- Organize doctors by their assigned department, specialization, and standard consultation fee.
- Track doctor activity and patient visit numbers over time.

### 3.3 Appointments & Outpatient Consultations
- Book appointments that link a specific patient with a specific doctor for a given date and time.
- Track each appointment using three clear stages: `Scheduled`, `Completed`, or `Cancelled`.
- Record clinical diagnoses (notes and dates) resulting from completed visits.
- Keep a complete, chronological consultation history for every patient.

### 3.4 Inpatient Admissions & Room Allocation
- Track room inventory, room types (e.g., General Ward, ICU, Private), daily rates, and current availability.
- Record inpatient admissions, room assignments, and discharge details.
- Automatically calculate stay duration and room charges upon discharge.

### 3.5 Pharmacy & Prescriptions
- Maintain a master list of available medicines, manufacturers, and unit prices.
- Connect prescriptions directly to patient appointments.
- Allow multiple medicines to be added to a single prescription, specifying dosage instructions and duration in days for each item.

### 3.6 Billing & Revenue Management
- Log payments made for outpatient appointments or inpatient admissions.
- Capture payment amount, payment date, and payment method (Cash, Card, UPI, or Insurance).
- Generate clear revenue reports filtered by date, department, or patient.

---

## 4. Business Rules

To keep the database clean and accurate, the system enforces these ground rules:

1. **Unique Patient ID:** Every patient gets a single unique `patient_id` upon registration.
2. **Single Department Assignment:** Each doctor belongs to **exactly one** department.
3. **Appointment Pairings:** Each appointment links **one patient** and **one doctor**.
4. **One Active Admission Per Room:** A room can only host **one active admission** at a time. A new patient cannot be assigned to an occupied room until the previous occupant is discharged.
5. **Flexible Prescriptions:** A single prescription can list **many medicines**, and a single medicine can appear across **many prescriptions**.
6. **Appointment-Backed Clinical Records:** Prescriptions and diagnoses can only be created as a result of a valid, completed appointment.
7. **Traceable Payments:** Every payment record must belong to a valid patient and link directly to an appointment or admission.
8. **Fixed Status Values:** Appointment statuses are strictly limited to `Scheduled`, `Completed`, or `Cancelled`.
9. **Central Pharmacy Catalog:** All prescribed medicines must come directly from the master medicine catalog.

---

## 5. System Assumptions

Our design relies on the following practical assumptions:

1. **One Transaction Per Event:** A single payment covers **either** an outpatient appointment **or** an inpatient stay (not combined into one single transaction).
2. **Logical Discharge Dates:** A patient **cannot be discharged before being admitted** (the discharge date must be equal to or after the admission date).
3. **Single Active Admission Per Patient:** A patient can only have **one active admission** at any given point in time.
4. **Single Currency:** All consultation fees, daily room rates, medicine prices, and payments use one standard currency.
5. **Fixed Consultation Fees:** A doctor's consultation fee is set at the doctor level and remains consistent across standard visits.
6. **Permanent Historical Records:** Past patient visits, admissions, and financial records are kept permanently for history and auditing purposes—nothing is deleted.

---

## 6. Non-Functional Requirements

- **Data Integrity:** Primary and Foreign Keys connect tables cleanly without leaving orphaned records behind.
- **Input Rules:** Rules like `NOT NULL` (required fields), `UNIQUE` (preventing duplicate IDs or phone numbers), and `CHECK` constraints (keeping fees positive and statuses valid) keep data accurate.
- **Normalization (3NF):** Tables are organized up to Third Normal Form to prevent repeating data unnecessarily.
- **Readable Naming:** Clear, standard column and table names are used throughout (`snake_case` format, like `patient_id` or `consultation_fee`).
- **Fast Lookups:** Indexes on primary keys and frequently searched fields (like phone numbers) keep queries fast.
- **Room to Grow:** The database is structured so future modules (like insurance claims or live pharmacy stock tracking) can be added without breaking existing tables.

---

## 7. Project Scope

| Area | Included in Current System | Kept for Future Iterations |
|---|---|---|
| **Patients** | Registration, demographic profiles, full visit history | Online patient portal, self-service logins |
| **Doctors** | Doctor profiles, department mapping, consultation fees | Duty rosters, shift scheduling |
| **Appointments** | Booking, status tracking (`Scheduled`/`Completed`/`Cancelled`), diagnoses | Online patient booking, automated SMS/Email reminders |
| **Admissions** | Room availability, admission & discharge tracking | Bed-level tracking, nurse assignments |
| **Pharmacy** | Master medicine catalog, prescription details (dosage/duration) | Real-time stock levels, supplier orders |
| **Billing** | Logging payments against visits/stays, payment modes | Automated PDF invoice printing, insurance claim management |
| **Reporting** | Standard SQL queries for revenue, workloads, and room usage | Live visual dashboards |
| **Security** | Relational constraints and database-level rules | User login accounts, role-based access control (RBAC) |

---

## 8. Conclusion

MediCare is a practical, well-structured database built to streamline daily hospital operations. By unifying patient records, doctor allocations, appointments, room admissions, prescriptions, and billing into one clean structure, it eliminates confusion and keeps data reliable.

This requirement document forms the blueprint for the upcoming project phases: ER Diagramming, Relational Mapping, 3NF Normalization, SQL Table Creation, Sample Data Insertion, and Business Queries.
