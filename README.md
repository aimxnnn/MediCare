# MediCare README 

This repository contains our DBMS course project (Team 1). We designed and implemented a relational database for a hospital, MediCare, covering patient registrations, doctors and departments, appointments, room admissions, prescriptions, and billing, consolidated into a single connected system rather than scattered spreadsheets.

## Team 1

| Name | USN |
|---|---|
| Adib Fareed Hasan | AU25UG-001 |
| A Akshay | AU25UG-067 |
| Abhishek Nayak | AU25UG-088 |
| Aditya Sivaji Perumalla | AU25UG-002 |
| Aiman Patil | AU25UG-075 |
| Ayushman Anand | AU25UG-007 |

## Overview

A hospital handles a large volume of interrelated data: patients, doctors across different departments, outpatient consultations, inpatient admissions, prescriptions containing multiple medicines, and payments for all of it. This project models all of that as 11 connected tables rather than leaving it scattered across separate spreadsheets, which is the usual cause of duplicate patient records and double-booked rooms.

The database supports the following:
- Registering patients and keeping their basic details on file
- Doctors organised by department, specialisation, and consultation fee
- Booking appointments and tracking whether they're scheduled, completed, or cancelled
- Admitting patients into rooms and recording discharge
- Diagnoses and prescriptions linked to the actual appointment they came from
- Medicines on a prescription (a prescription can have more than one)
- Payments, tied to exactly one appointment or one admission (never both)

## Built With

MySQL 8.0+. Note that `CHECK` constraints are only enforced from MySQL 8.0.16 onward, so a local setup should use that version or later.

## Folder Structure

```
schema/
  create_tables.sql          -> creates the database + all 11 tables + constraints + the payments_with_patient view
data/
  insert_data.sql            -> sample data for every table (20 patients, 32 appointments, 37 payments, etc.)
queries/
  queries.sql                -> all the business question queries (Q1-Q11)
diagrams/
  ER_Diagram.png             -> the ER diagram
  Relational_Schema.png      -> the relational schema diagram
docs/
  Problem_Analysis_and_Requirements.md -> problem statement, requirements, assumptions
  Normalisation.md           -> functional dependencies, 1NF-3NF walkthrough
  Design_Rationale.md        -> why we made the design decisions we made
  data_fixes.sql             -> record of data-quality issues found in the sample data and how each was fixed
  Project_Report.md          -> the full project report
```

## Setup

Run the following in order; each script depends on the one before it:

```bash
mysql -u your_username -p < schema/create_tables.sql
mysql -u your_username -p < data/insert_data.sql
mysql -u your_username -p < queries/queries.sql
```

Note: `create_tables.sql` begins with `DROP DATABASE IF EXISTS medicare`. If a `medicare` database already exists locally, back it up before running this, as it will be dropped and rebuilt.

## Business Questions

The brief required the following:

1. Which doctors have treated the most patients
2. Which department has the most appointments
3. Average consultation fee by department
4. Registered patients who've never actually visited
5. Most frequently prescribed medicines
6. Patients admitted more than once
7. Monthly revenue over time

In addition, the team included the following:

8. Room occupancy — how often each room's actually been used
9. Average length of stay per room type
10. Estimated revenue per doctor
11. Cancellation rate per department

The SQL for all queries is in `queries/queries.sql`.

## Design Notes

The database is normalised up to 3NF. The prescription-to-medicine relationship is resolved through a dedicated bridge table, as it is many-to-many, and payments are linked to exactly one of an appointment or an admission, enforced by `chk_payment_reference`. Notably, `payments` does **not** store `patient_id` directly — the patient is fully derivable through the linked appointment or admission, so storing it again would be a transitive dependency. A view, `payments_with_patient`, is provided in `schema/create_tables.sql` for queries that need the patient resolved. The full reasoning behind these decisions is documented in `docs/Design_Rationale.md`.e

## Data Quality

The sample data went through a review pass that caught and corrected six issues — a prescription/appointment mismatch, a room double-booking, stale room availability flags, two admission payments that didn't match `daily_charge × length of stay`, four appointments assigned to the wrong doctor, and two diagnoses that were pediatric/neonatal in nature but attached to adult patients (resolved by adding two new patients). The full writeup, including the verification query used for each, is in `docs/data_fixes.sql`.

## Team Contributions

- Requirement analysis — Adib
- ER diagram and relational design — Akshay
- Normalisation — Aditya
- Implementation and queries — Ayushman
- Repository and documentation — Aiman and Abhishek
