# MediCare — Design Rationale

**Project:** Hospital Information and Management Database
**Team:** Team 1
**RDBMS:** MySQL 8.0+
**Canonical schema file:** `schema/create_tables.sql`
**Document path:** `docs/design_rationale.md`

---

## 1. Purpose

This document explains *why* MediCare is built the way it is — the decisions behind
the schema, the constraints, and the assumptions the team made where the brief left
room for interpretation. It is the single place all design-rationale content lives;
this was previously split across the implementation notes, the normalisation
document, and the Stage 1 requirements document. Everything below has been checked
against `schema/create_tables.sql` and the final, corrected `data/insert_data.sql`.

---

## 2. RDBMS Choice

MySQL 8.0+ was chosen as the implementation target. MySQL 8.0.16 was specifically
required because `CHECK` constraints are only enforced from that version onward —
an earlier MySQL version would silently accept rows that violate constraints such
as `chk_payment_amount` or `chk_admission_dates`.

---

## 3. Table-Level Design Decisions

### 3.1 Payments: linking to exactly one of an appointment or an admission, without storing the patient

The brief's suggested `payments` table included `patient_id`, `amount`,
`payment_date`, and `mode`, but no way to tell *what* a payment was actually for.
The team added two nullable foreign keys, `appointment_id` and `admission_id`,
with `chk_payment_reference` enforcing that exactly one of the two is filled —
never both, never neither:

```sql
CONSTRAINT chk_payment_reference
    CHECK (
        (appointment_id IS NOT NULL AND admission_id IS NULL)
        OR (appointment_id IS NULL AND admission_id IS NOT NULL)
    )
```

This reflects the business rule that **a single payment covers either one
outpatient appointment or one inpatient stay, never both**, matching the
relational schema diagram's stated constraint. The sample data's 37 payment
rows each fill exactly one of the two columns.

**`patient_id` is deliberately not stored on `payments`.** A payment's patient is
fully determined by `appointment_id → appointments.patient_id` or
`admission_id → admissions.patient_id`. Storing `patient_id` again on `payments`
would make it transitively dependent on a non-key attribute (`appointment_id` or
`admission_id`) rather than directly on `payment_id` — a textbook 3NF violation —
and would also risk the stored value drifting out of sync with the appointment or
admission it's actually tied to. Instead, a view resolves it when needed:

```sql
CREATE OR REPLACE VIEW payments_with_patient AS
SELECT pay.payment_id,
       COALESCE(a.patient_id, ad.patient_id) AS patient_id,
       pay.appointment_id,
       pay.admission_id,
       pay.amount,
       pay.payment_date,
       pay.mode
FROM payments pay
LEFT JOIN appointments a ON a.appointment_id = pay.appointment_id
LEFT JOIN admissions ad  ON ad.admission_id = pay.admission_id;
```

**Referential actions:** the `appointment_id` and `admission_id` foreign keys on
`payments` use `ON UPDATE RESTRICT ON DELETE RESTRICT` rather than the
`ON UPDATE CASCADE` used elsewhere in the schema — a deliberate exception.
Payment records are financial history, so the team decided a key renumbering on
an appointment or admission should never be allowed to silently ripple into
billing records; any such change has to be handled explicitly.

### 3.2 Prescription–Medicine: resolving the M:N relationship

A prescription can contain many medicines, and a medicine can appear in many
prescriptions, so this cannot be modelled with a foreign key on either side alone.
The team introduced the bridge table `prescription_medicines` with a composite
primary key `(prescription_id, medicine_id)`, carrying the relationship-specific
attributes `dosage` and `duration_days` — these two values describe *this
medicine, in this prescription*, and would not belong on either `prescriptions`
or `medicines` individually.

### 3.3 Referential actions: master data vs. dependent detail vs. financial records

Three different `ON DELETE` policies were used, and the choice was deliberate:

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
medicare;` so it can be re-run from a clean state at any time.
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
7. **Every payment traces to exactly one appointment or admission, and the
   patient is derived from that link** — implemented via `chk_payment_reference`
   and the `payments_with_patient` view (Section 3.1).
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

---

## 8. Sample Data Design Rationale

The data in `data/insert_data.sql` was built deliberately rather than randomly,
so every business question returns a genuine, non-trivial result. A review pass
also caught and corrected six data-quality issues in the original draft of the
data — the full detail and verification query for each is in
`docs/data_fixes.sql`:

1. Prescriptions 19–29 were re-pointed to the correct appointment sequence
   (`20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31`) — appointments 19 and 24 were
   Cancelled/Scheduled and correctly have no prescription.
2. Admission 9 was moved off room 3 (where it was double-booked against
   admission 3) to room 4, which matches its Semi-Private rate.
3. `rooms.is_available` was recalculated for rooms 1 and 7 to reflect which
   rooms actually have a still-open admission.
4. Admission 1's payment was corrected from ₹4,800 to ₹30,000 (4 nights in ICU
   at ₹7,500/night), and admission 2's from ₹3,800 to ₹11,400 (3 nights in a
   Private room at ₹3,800/night).
5. Appointments 5, 15, 18, and 26 had their doctor reassigned to match their
   diagnosis and the fee actually billed — e.g. appointment 5 (an ankle sprain
   billed at ₹800) moved from Dr. Kulkarni (Neonatology) to Dr. Shetty (Sports
   Medicine).
6. Two new patients were added — an infant (Baby Reyansh Rao) and a child
   (Tanvi Hegde) — and appointments 9, 15, and 27, which carry pediatric or
   neonatal diagnoses, were reassigned to them instead of the adult patients
   they were originally attached to.

| Design choice | Why |
|---|---|
| 5 of 20 patients have zero appointments | Needed for Q4 to return real rows. Patient 8 joined this group as a side effect of fix #6, which moved her only two appointments to the newly added pediatric patients. |
| 2 patients (Arjun Reddy, Amit Bansal) each have 2 admissions | Needed for Q6's `HAVING COUNT > 1` |
| Appointment and payment dates span Jan–Jun 2026 | Gives Q7 six distinct months to group by |
| Ibuprofen and Amlodipine appear far more often than other medicines | Gives Q5 a clear, non-tied top result |
| Consultation fees range ₹550–₹1,500 across departments | Gives Q3 a real spread rather than near-identical values |
| 1 appointment `Cancelled`, 2 `Scheduled` (not yet `Completed`) | Exercises the `status` CHECK and feeds Q11's cancellation-rate calculation |
| 2 admissions have `discharge_date IS NULL` | Represents patients currently admitted; also confirms Q9 correctly excludes them from the average-stay calculation |
| 2 patients added specifically for pediatric/neonatal diagnoses | Keeps every diagnosis clinically consistent with the patient it's attached to |

Row counts after loading:

| Table | Rows |
|---|---|
| departments | 5 |
| doctors | 9 |
| patients | 20 |
| rooms | 8 |
| medicines | 12 |
| appointments | 32 |
| admissions | 10 |
| diagnoses | 29 |
| prescriptions | 29 |
| prescription_medicines | 39 |
| payments | 37 |

---

## 9. Query Design Notes

**Q1 — Doctors who treated the most patients.** Counts *distinct* patients per
doctor (`COUNT(DISTINCT a.patient_id)`), not appointment count, since a doctor
seeing the same patient five times should not outrank one who saw five different
patients once each. **After fix #5's doctor reassignments, Dr. Suresh Iyer and
Dr. Nithya Shetty — both in Orthopedics — now legitimately tie at 4 distinct
patients each.** Worth being ready to discuss a tie-breaking approach (e.g. a
secondary `ORDER BY`) in the viva.

**Q2 — Busiest department.** Joins appointments → doctors → departments and
takes the top department by raw appointment count.

**Q3 — Average consultation fee by department.** Straightforward `AVG` +
`GROUP BY`; `COUNT(d.doctor_id)` is included alongside so the average isn't
read as if every department had equal representation.

**Q4 — Patients who never visited.** Uses a `LEFT JOIN ... WHERE
appointment_id IS NULL` rather than `NOT EXISTS` — both are equivalent here,
but the `LEFT JOIN` form was chosen since it directly returns the patient's
details in the same query. **Now returns 5 patients** (previously 4) — patient
8 (Neha Joshi) joined the list after fix #6 moved her only appointments to the
newly added pediatric patients.

**Q5 — Most-prescribed medicines.** Joins through the `prescription_medicines`
bridge table, since medicine frequency can't be read off `prescriptions` or
`medicines` alone — this is the query that most directly demonstrates why the
M:N relationship needed its own table.

**Q6 — Repeat admissions.** `GROUP BY patient_id HAVING COUNT(*) > 1` — the
`HAVING` clause is necessary here rather than `WHERE`, since the filter
applies to an aggregated value.

**Q7 — Monthly revenue.** `DATE_FORMAT(payment_date, '%Y-%m')` groups payments
into calendar months regardless of day — this is the MySQL-specific piece of
this query; porting to PostgreSQL would use `TO_CHAR(payment_date, 'YYYY-MM')`
instead. Does not touch `patient_id` at all, consistent with `payments` no
longer storing it (Section 3.1).

**Q8 — Room occupancy (own question).** Uses a `LEFT JOIN` from `rooms` to
`admissions` so a never-used room still appears in the results with a count of
zero, rather than disappearing — a plain `JOIN` would hide unused inventory,
which is the more useful thing for a hospital to know. After fix #2 moved
admission 9 into room 4, every room in the current data has at least one
admission, so this behaviour currently has no example to show — worth
mentioning in the viva as defensive design rather than something the sample
data happens to demonstrate.

**Q9 — Average length of stay by room type (own question).** Filters to
`discharge_date IS NOT NULL` since `DATEDIFF` against a `NULL` discharge date
would either error or silently return `NULL`, which would understate the true
average for still-occupied rooms.

**Q10 — Revenue per doctor (own question).** Multiplies each doctor's fixed
consultation fee by their count of `Completed` appointments — a
simplification, since it assumes every consultation was billed at the
doctor's list price, but it gives a directionally useful ranking without
needing to join through `payments`, which aren't itemised per consultation in
this schema. Rankings shift slightly after fix #5's doctor reassignments.

**Q11 — Cancellation rate per department (own question).** Uses a
`SUM(CASE WHEN ... THEN 1 ELSE 0 END)` pattern rather than a second filtered
query, so cancelled and total counts come from a single pass over the same
rows and can't drift out of sync with each other.
