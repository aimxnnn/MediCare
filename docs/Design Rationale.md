# MediCare — Stage 9: Design Rationale

**Project:** Hospital Information and Management Database
**Team:** Team 1
**RDBMS:** MySQL 8.0+
**Canonical schema file:** `schema/create_tables.sql`
**Document path:** `docs/stage9_design_rationale.md`

---

## 1. Purpose

This document explains *why* MediCare is built the way it is — the decisions behind
the schema, the constraints, and the assumptions the team made where the brief left
room for interpretation. It is the single place all design-rationale content lives;
previously this was split across the implementation notes, the normalisation
document, and the Stage 1 requirements document. Everything below has been checked
against `schema/create_tables.sql`, the version of the schema the project actually
runs on.

---

## 2. RDBMS Choice

MySQL 8.0+ was chosen as the implementation target. MySQL 8.0.16 was specifically
required because `CHECK` constraints are only enforced from that version onward —
an earlier MySQL version would silently accept rows that violate constraints such
as `chk_payment_amount` or `chk_admission_dates`.

---

## 3. Table-Level Design Decisions

### 3.1 Payments: linking to either an appointment or an admission

The brief's suggested `payments` table only included `patient_id`, `amount`,
`payment_date`, and `mode` — with no way to tell *what* a payment was actually for.
The team added two nullable foreign keys, `appointment_id` and `admission_id`,
plus a `CHECK` constraint (`chk_payment_reference`) requiring at least one of them
to be filled:

```sql
CONSTRAINT chk_payment_reference
    CHECK (appointment_id IS NOT NULL OR admission_id IS NOT NULL)
```

This reflects the business rule that **a single payment covers either one
outpatient appointment or one inpatient stay, never both at once** — the two
foreign keys are never both filled for the same payment in the sample data.

**Referential actions:** `patients` uses `ON DELETE RESTRICT` like the rest of the
master-data tables (Section 3.3). The `appointment_id` and `admission_id` foreign
keys use `ON UPDATE RESTRICT ON DELETE RESTRICT` rather than the `ON UPDATE
CASCADE` used elsewhere in the schema — this is a deliberate exception: payment
records are financial history, so the team decided a key renumbering on an
appointment or admission should never be allowed to silently ripple into billing
records. Any such change has to be handled explicitly rather than cascading.

### 3.2 Prescription–Medicine: resolving the M:N relationship

A prescription can contain many medicines, and a medicine can appear in many
prescriptions, so this cannot be modelled with a foreign key on either side alone.
The team introduced the bridge table `prescription_medicines` with a composite
primary key `(prescription_id, medicine_id)`, carrying the relationship-specific
attributes `dosage` and `duration_days` — these two values describe *this
medicine, in this prescription*, and would not belong on either `prescriptions`
or `medicines` individually.

### 3.3 Referential actions: master data vs. dependent detail

Two different `ON DELETE` policies were used, and the choice was deliberate:

| Data type | Tables | Policy | Reason |
|---|---|---|---|
| Master / reference data | `doctors`, `patients`, `rooms` | `ON DELETE RESTRICT` | Prevents deleting a doctor, patient, or room that is still referenced by transactional records — this protects the integrity of the hospital's operational history. |
| Dependent detail records | `diagnoses`, `prescriptions`, `prescription_medicines` | `ON DELETE CASCADE` | A diagnosis or prescription has no meaning without its parent appointment, so it should be removed automatically if the appointment is. |
| Financial records | `payments` | `ON DELETE RESTRICT` (both FKs) | Payments are treated as permanent history and are never auto-deleted (see Section 3.1). |

All foreign keys across the schema use `ON UPDATE CASCADE` **except** the two on
`payments`, which use `ON UPDATE RESTRICT` for the reason given in 3.1.

### 3.4 Fixed-value fields: CHECK instead of ENUM

Fields with a fixed set of valid values — `gender`, `blood_group`, appointment
`status`, and payment `mode` — are constrained with `CHECK (... IN (...))` rather
than MySQL's `ENUM` type. `CHECK` is portable to PostgreSQL or SQL Server if the
team ever needs to migrate, whereas `ENUM` is MySQL-specific and would need to be
rebuilt from scratch on another RDBMS.

### 3.5 Data types

- **`DECIMAL(10,2)`** for every money field (`consultation_fee`, `daily_charge`,
  `unit_price`, `amount`) rather than `FLOAT`, to avoid floating-point rounding
  errors on currency values.
- **`DATETIME`** for `appointment_date`, since the time of day matters for
  scheduling and avoiding double-bookings.
- **`DATE`** for `admit_date`, `discharge_date`, `issued_date`, and
  `payment_date`, since day-level granularity is sufficient for these.

### 3.6 Indexing

MySQL indexes every foreign key column automatically. On top of that, the team
added explicit indexes on columns the business queries filter or group on
directly: `appointment_date` and `status` on `appointments`, `admit_date` and
`discharge_date` together on `admissions`, `payment_date` on `payments`, and
`name` on `patients`.

### 3.7 Database and script safety

The schema script opens with `DROP DATABASE IF EXISTS medicare; CREATE DATABASE
medicare;` so it can be re-run from a clean state at any time, followed by
defensive `DROP TABLE IF EXISTS` statements in reverse dependency order as a
safety net if only the tables — not the whole database — need to be rebuilt.
Tables are created parents-before-children, so every foreign key reference
already exists at creation time:

```
departments → doctors → patients → rooms → appointments → diagnoses →
admissions → medicines → prescriptions → prescription_medicines → payments
```

---

## 4. Business Rules Reflected in the Design

1. **Unique patient ID** — every patient receives a single `patient_id` on
   registration (auto-increment primary key).
2. **One department per doctor** — `doctors.department_id` is `NOT NULL`, so
   every doctor belongs to exactly one department.
3. **One patient, one doctor per appointment** — `appointments` has non-nullable
   foreign keys to both.
4. **One active admission per room at a time** — this is documented as a design
   rule rather than enforced by a database constraint; MySQL's standard `CHECK`
   syntax cannot express "no overlapping date ranges" across rows. The team's
   position is that this is enforced at the application level, and this is
   flagged as a known limitation rather than silently assumed to be handled.
5. **Prescriptions can hold many medicines, and medicines can appear in many
   prescriptions** — implemented via `prescription_medicines` (Section 3.2).
6. **Diagnoses and prescriptions only exist against a valid appointment** —
   both have a `NOT NULL` foreign key to `appointments`.
7. **Every payment traces to a patient and to an appointment or admission** —
   implemented via `chk_payment_reference` (Section 3.1).
8. **Appointment status is one of three fixed values** — enforced by
   `chk_appointment_status`.
9. **All prescribed medicines come from the medicines master list** — enforced
   by the foreign key `fk_pm_medicine`.

---

## 5. Assumptions

1. **One transaction per payment** — a payment covers either one appointment or
   one admission, never a combined bill.
2. **Discharge cannot precede admission** — enforced by `chk_admission_dates`.
3. **One active admission per patient at a time** — assumed, not enforced at the
   database level (see Section 4, item 4).
4. **Single currency** — all fees, charges, prices, and payments are assumed to
   be in one currency; no currency column exists.
5. **Fixed consultation fee per doctor** — a doctor's fee is stored once on the
   `doctors` row and assumed constant across their standard visits, rather than
   varying per appointment.
6. **Records are permanent** — past appointments, admissions, and payments are
   kept for history and auditing; nothing in the design is built to be deleted
   as a matter of course (reflected in the `RESTRICT` policies in Section 3.3).

---

## 6. Anomalies Avoided by the Design

| Anomaly | How it's avoided |
|---|---|
| **Update anomaly** | Department, doctor, room, and medicine details live in their own master tables, so a single change doesn't require updating many repeated transaction rows. |
| **Insert anomaly** | A department, doctor, medicine, or room can be added independently, without needing an unrelated appointment or payment to exist first. |
| **Delete anomaly** | Deleting an appointment (cascading to its diagnoses and prescriptions) does not delete the doctor, patient, medicine, or department master records. |

---

## 7. Known Limitations

- "One active admission per room" and "one active admission per patient" are
  business rules the team has designed around, but they are not enforced by a
  database constraint or trigger — this is a deliberate simplification, noted
  here rather than left implicit.
- Doctor consultation fees are fixed per doctor rather than per appointment, so
  historical fee changes are not tracked; if a doctor's fee changes, past
  appointments are not re-priced but also don't retain the fee that applied at
  the time of the visit.
- The `payments` design assumes a payment is settled in a single transaction;
  partial or instalment payments are out of scope for the current design.
