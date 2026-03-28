# Healthcare Domain — Hospital Management System (HMS) Database Design

## TOC
1. Core Patient Management
2. Clinical / EMR (Encounters, Diagnoses, Orders)
3. Bed Management
4. Laboratory Management (full test lifecycle)
5. Pharmacy & Medication Management
6. Pharmacy Inventory Management
7. Radiology & Imaging
8. Nursing & Ward Management
9. Finance & Billing
10. HR & Staff Management
11. Accounting (GL, AP, AR)
12. Healthcare-specific indexing & compliance notes

All tables assume shared-schema multi-tenancy with `tenant_id` on every table.
RLS policies must be applied to all tables (see main SKILL.md Phase 2.4).

---

## 1. CORE PATIENT MANAGEMENT

```sql
CREATE TABLE patients (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL,
    mrn              VARCHAR(30) NOT NULL,   -- Medical Record Number
    first_name       VARCHAR(100) NOT NULL,
    middle_name      VARCHAR(100),
    last_name        VARCHAR(100) NOT NULL,
    date_of_birth    DATE NOT NULL,
    gender           VARCHAR(20) NOT NULL,   -- 'male','female','other','unknown'
    blood_group      VARCHAR(5),             -- 'A+','B-', etc.
    national_id      VARCHAR(50),
    phone_primary    VARCHAR(20),
    phone_secondary  VARCHAR(20),
    email            VARCHAR(255),
    address          JSONB,                  -- {street, city, state, zip, country}
    emergency_contact JSONB,                 -- [{name, relation, phone}]
    allergies        JSONB,                  -- [{drug, severity, reaction}]
    chronic_conditions TEXT[],
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_vip           BOOLEAN DEFAULT FALSE,
    notes            TEXT,
    deleted_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, mrn)
);

CREATE TABLE patient_insurance (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    patient_id      UUID NOT NULL,
    insurer_name    VARCHAR(200) NOT NULL,
    policy_number   VARCHAR(100) NOT NULL,
    group_number    VARCHAR(100),
    plan_type       VARCHAR(50),            -- 'HMO','PPO','Medicare','Medicaid'
    coverage_start  DATE NOT NULL,
    coverage_end    DATE,
    copay_amount    NUMERIC(10,2),
    is_primary      BOOLEAN NOT NULL DEFAULT TRUE,
    subscriber_name VARCHAR(200),
    subscriber_dob  DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (patient_id) REFERENCES patients(id)
);

-- Indexes
CREATE INDEX idx_patients_tenant_mrn ON patients(tenant_id, mrn);
CREATE INDEX idx_patients_tenant_name ON patients(tenant_id, last_name, first_name);
CREATE INDEX idx_patients_tenant_dob ON patients(tenant_id, date_of_birth);
CREATE INDEX idx_patients_active ON patients(tenant_id) WHERE deleted_at IS NULL;
```

---

## 2. CLINICAL / EMR

```sql
CREATE TABLE encounters (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    patient_id      UUID NOT NULL,
    encounter_number VARCHAR(30) NOT NULL,
    encounter_type  VARCHAR(30) NOT NULL,  -- 'outpatient','inpatient','emergency','telemedicine'
    status          VARCHAR(20) NOT NULL DEFAULT 'open',
    department_id   UUID NOT NULL,
    attending_doctor_id UUID NOT NULL,
    chief_complaint TEXT,
    admission_date  TIMESTAMPTZ,
    discharge_date  TIMESTAMPTZ,
    discharge_type  VARCHAR(50),           -- 'improved','transferred','ama','deceased'
    bed_id          UUID,
    visit_type      VARCHAR(30),           -- 'new','follow_up','emergency'
    referral_source VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, encounter_number),
    FOREIGN KEY (patient_id) REFERENCES patients(id)
);

CREATE TABLE diagnoses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    encounter_id    UUID NOT NULL,
    patient_id      UUID NOT NULL,
    icd10_code      VARCHAR(20) NOT NULL,
    icd10_description TEXT NOT NULL,
    diagnosis_type  VARCHAR(20) DEFAULT 'primary',  -- 'primary','secondary','comorbidity'
    status          VARCHAR(20) DEFAULT 'confirmed', -- 'suspected','confirmed','ruled_out'
    diagnosed_by    UUID NOT NULL,
    diagnosed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT
);

CREATE TABLE clinical_notes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    encounter_id    UUID NOT NULL,
    note_type       VARCHAR(30) NOT NULL,  -- 'SOAP','progress','discharge_summary','nursing'
    subjective      TEXT,   -- Patient complaints
    objective       TEXT,   -- Exam findings
    assessment      TEXT,   -- Clinical assessment
    plan            TEXT,   -- Treatment plan
    authored_by     UUID NOT NULL,
    authored_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    signed_at       TIMESTAMPTZ,
    amended_at      TIMESTAMPTZ,
    amendment_reason TEXT,
    is_confidential BOOLEAN DEFAULT FALSE
);

CREATE TABLE vital_signs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL,
    encounter_id     UUID NOT NULL,
    patient_id       UUID NOT NULL,
    recorded_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    recorded_by      UUID NOT NULL,
    temperature_c    NUMERIC(4,1),
    blood_pressure_systolic  SMALLINT,
    blood_pressure_diastolic SMALLINT,
    pulse_rate       SMALLINT,
    respiratory_rate SMALLINT,
    oxygen_saturation NUMERIC(4,1),
    weight_kg        NUMERIC(6,2),
    height_cm        NUMERIC(5,1),
    bmi              NUMERIC(4,1) GENERATED ALWAYS AS
                     (CASE WHEN height_cm > 0 THEN weight_kg / ((height_cm/100)^2) ELSE NULL END) STORED,
    pain_scale       SMALLINT CHECK (pain_scale BETWEEN 0 AND 10),
    blood_glucose    NUMERIC(5,1),  -- mg/dL
    notes            TEXT
);

-- Medical orders (lab, radiology, medication, procedure)
CREATE TABLE medical_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    encounter_id    UUID NOT NULL,
    patient_id      UUID NOT NULL,
    order_type      VARCHAR(20) NOT NULL,  -- 'lab','radiology','medication','procedure','referral'
    order_number    VARCHAR(30) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- 'pending','approved','in_progress','completed','cancelled'
    ordered_by      UUID NOT NULL,
    ordered_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    priority        VARCHAR(10) DEFAULT 'routine',  -- 'stat','urgent','routine'
    clinical_indication TEXT,
    notes           TEXT,
    approved_by     UUID,
    approved_at     TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    UNIQUE (tenant_id, order_number)
);
```

---

## 3. BED MANAGEMENT

```sql
CREATE TABLE facilities (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(200) NOT NULL,
    type            VARCHAR(50),   -- 'main_hospital','clinic','satellite'
    address         JSONB,
    contact         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE departments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    facility_id     UUID NOT NULL,
    name            VARCHAR(200) NOT NULL,
    code            VARCHAR(20) NOT NULL,
    type            VARCHAR(50),   -- 'icu','ward','emergency','surgery','maternity','pediatric'
    head_doctor_id  UUID,
    total_beds      SMALLINT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, code)
);

CREATE TABLE wards (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    department_id   UUID NOT NULL,
    name            VARCHAR(100) NOT NULL,
    floor           SMALLINT,
    wing            VARCHAR(20),
    capacity        SMALLINT NOT NULL,
    ward_type       VARCHAR(30),  -- 'general','private','icu','isolation','maternity'
    gender_restriction VARCHAR(10) DEFAULT 'mixed',  -- 'male','female','mixed'
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE beds (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    ward_id         UUID NOT NULL,
    department_id   UUID NOT NULL,
    bed_number      VARCHAR(20) NOT NULL,
    bed_type        VARCHAR(30) NOT NULL,  -- 'standard','icu','isolation','bariatric','birthing'
    status          VARCHAR(20) NOT NULL DEFAULT 'available',
    -- 'available','occupied','maintenance','cleaning','reserved'
    features        TEXT[],    -- ['oxygen','suction','cardiac_monitor','ventilator']
    last_occupied_at TIMESTAMPTZ,
    last_cleaned_at TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, bed_number)
);

CREATE TABLE bed_assignments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    bed_id          UUID NOT NULL,
    encounter_id    UUID NOT NULL,
    patient_id      UUID NOT NULL,
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by     UUID NOT NULL,
    released_at     TIMESTAMPTZ,
    released_by     UUID,
    release_reason  VARCHAR(50),   -- 'discharged','transferred','deceased'
    transfer_to_bed_id UUID,
    notes           TEXT,
    FOREIGN KEY (bed_id) REFERENCES beds(id),
    FOREIGN KEY (encounter_id) REFERENCES encounters(id)
);

-- Real-time bed availability view
CREATE VIEW bed_availability AS
SELECT
    b.tenant_id,
    b.id AS bed_id,
    b.bed_number,
    b.bed_type,
    b.status,
    w.name AS ward_name,
    d.name AS department_name,
    ba.patient_id AS current_patient_id,
    ba.assigned_at AS occupied_since,
    -- Days occupied
    CASE WHEN ba.id IS NOT NULL 
         THEN EXTRACT(EPOCH FROM (NOW() - ba.assigned_at))/86400 
         ELSE NULL END AS days_occupied
FROM beds b
JOIN wards w ON w.id = b.ward_id
JOIN departments d ON d.id = b.department_id
LEFT JOIN bed_assignments ba ON ba.bed_id = b.id AND ba.released_at IS NULL;

CREATE INDEX idx_beds_tenant_status ON beds(tenant_id, status);
CREATE INDEX idx_bed_assignments_active ON bed_assignments(tenant_id, bed_id) 
    WHERE released_at IS NULL;
```

---

## 4. LABORATORY MANAGEMENT — Full Test Lifecycle

```sql
-- Test catalog (master list of available tests)
CREATE TABLE lab_test_catalog (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    test_code       VARCHAR(30) NOT NULL,
    test_name       VARCHAR(200) NOT NULL,
    category        VARCHAR(50),  -- 'hematology','biochemistry','microbiology','serology','pathology'
    specimen_types  TEXT[] NOT NULL,  -- ['blood','urine','stool','swab','tissue']
    collection_instructions TEXT,
    processing_time_hours SMALLINT,  -- expected TAT (turnaround time)
    stat_processing_hours SMALLINT,
    normal_ranges   JSONB,  -- [{parameter, unit, male_min, male_max, female_min, female_max, age_group}]
    methodology     VARCHAR(100),
    is_active       BOOLEAN DEFAULT TRUE,
    requires_fasting BOOLEAN DEFAULT FALSE,
    price           NUMERIC(10,2),
    insurance_code  VARCHAR(20),  -- CPT/LOINC code
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, test_code)
);

-- Lab panel = group of tests ordered together
CREATE TABLE lab_panels (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    panel_code      VARCHAR(30) NOT NULL,
    panel_name      VARCHAR(200) NOT NULL,
    tests           UUID[] NOT NULL,   -- array of lab_test_catalog IDs
    is_active       BOOLEAN DEFAULT TRUE,
    price           NUMERIC(10,2),
    UNIQUE (tenant_id, panel_code)
);

-- Lab request (linked to medical order)
CREATE TABLE lab_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    order_id        UUID NOT NULL REFERENCES medical_orders(id),
    encounter_id    UUID NOT NULL,
    patient_id      UUID NOT NULL,
    lab_number      VARCHAR(30) NOT NULL,  -- accession number
    status          VARCHAR(20) NOT NULL DEFAULT 'ordered',
    -- lifecycle: ordered → specimen_collected → received → processing → completed → reported → verified
    requesting_doctor_id UUID NOT NULL,
    priority        VARCHAR(10) DEFAULT 'routine',  -- 'stat','urgent','routine'
    clinical_notes  TEXT,
    ordered_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    required_by     TIMESTAMPTZ,  -- STAT deadline
    UNIQUE (tenant_id, lab_number)
);

-- Individual test within a request
CREATE TABLE lab_request_tests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    lab_request_id  UUID NOT NULL REFERENCES lab_requests(id),
    test_id         UUID NOT NULL REFERENCES lab_test_catalog(id),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    notes           TEXT
);

-- Specimen collection and tracking
CREATE TABLE lab_specimens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    lab_request_id  UUID NOT NULL REFERENCES lab_requests(id),
    specimen_id     VARCHAR(30) NOT NULL,  -- barcode/label
    specimen_type   VARCHAR(30) NOT NULL,  -- 'blood','urine','stool','swab','tissue','csf'
    collection_method VARCHAR(50),         -- 'venipuncture','fingerstick','catheter','biopsy'
    collected_at    TIMESTAMPTZ,
    collected_by    UUID,
    volume_ml       NUMERIC(5,2),
    condition       VARCHAR(20) DEFAULT 'acceptable',  -- 'acceptable','rejected','insufficient'
    rejection_reason VARCHAR(200),
    received_at     TIMESTAMPTZ,
    received_by     UUID,
    storage_location VARCHAR(50),  -- 'fridge_A','freezer_2', etc.
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    UNIQUE (tenant_id, specimen_id)
);

-- Test results — the most critical table in lab module
CREATE TABLE lab_results (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    lab_request_id  UUID NOT NULL REFERENCES lab_requests(id),
    test_id         UUID NOT NULL REFERENCES lab_test_catalog(id),
    specimen_id     UUID REFERENCES lab_specimens(id),
    -- Result data
    parameter_name  VARCHAR(200) NOT NULL,
    result_value    VARCHAR(100),       -- numeric or text result
    result_numeric  NUMERIC(15,6),      -- parsed numeric for calculations
    result_unit     VARCHAR(30),
    reference_range VARCHAR(100),       -- e.g. '3.5–5.5'
    abnormal_flag   VARCHAR(5),         -- 'H','L','HH','LL','A' (LOINC standard)
    -- 'H'=High, 'L'=Low, 'HH'=Critical High, 'LL'=Critical Low, 'A'=Abnormal
    is_critical     BOOLEAN DEFAULT FALSE,
    critical_notified_at TIMESTAMPTZ,
    critical_notified_by UUID,
    -- Workflow
    status          VARCHAR(20) NOT NULL DEFAULT 'preliminary',
    -- 'preliminary','final','amended','corrected','cancelled'
    result_method   VARCHAR(100),
    analyzer_id     VARCHAR(50),
    -- Authorship chain (full traceability)
    resulted_by     UUID,       -- lab tech who entered result
    resulted_at     TIMESTAMPTZ DEFAULT NOW(),
    reviewed_by     UUID,       -- senior lab tech
    reviewed_at     TIMESTAMPTZ,
    verified_by     UUID,       -- pathologist/lab director sign-off
    verified_at     TIMESTAMPTZ,
    amended_at      TIMESTAMPTZ,
    amendment_reason TEXT,
    notes           TEXT,
    raw_instrument_data JSONB   -- machine output for audit
);

-- Critical value notification log
CREATE TABLE lab_critical_notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    result_id       UUID NOT NULL REFERENCES lab_results(id),
    notified_who    UUID NOT NULL,  -- doctor/nurse notified
    notified_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    method          VARCHAR(20),    -- 'phone','paging','app'
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID,
    notes           TEXT
);

-- Indexes for lab module
CREATE INDEX idx_lab_requests_tenant_status ON lab_requests(tenant_id, status);
CREATE INDEX idx_lab_requests_patient ON lab_requests(tenant_id, patient_id);
CREATE INDEX idx_lab_results_request ON lab_results(tenant_id, lab_request_id);
CREATE INDEX idx_lab_results_critical ON lab_results(tenant_id) WHERE is_critical = TRUE;
CREATE INDEX idx_lab_specimens_barcode ON lab_specimens(tenant_id, specimen_id);
```

---

## 5. PHARMACY & MEDICATION MANAGEMENT

```sql
-- Drug master catalog
CREATE TABLE drugs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    drug_code       VARCHAR(30) NOT NULL,
    generic_name    VARCHAR(200) NOT NULL,
    brand_names     TEXT[],
    drug_class      VARCHAR(100),   -- 'antibiotic','analgesic','antihypertensive'
    dosage_forms    TEXT[],         -- ['tablet','capsule','injection','syrup','inhaler']
    strengths       TEXT[],         -- ['250mg','500mg','1g']
    route_of_admin  TEXT[],         -- ['oral','iv','im','sublingual','topical']
    controlled_substance BOOLEAN DEFAULT FALSE,
    schedule        VARCHAR(10),    -- 'Schedule II','Schedule III', etc.
    requires_prescription BOOLEAN DEFAULT TRUE,
    contraindications TEXT[],
    interactions    JSONB,          -- [{drug_id, severity, description}]
    storage_conditions VARCHAR(100), -- 'refrigerate','room_temp','avoid_light'
    is_active       BOOLEAN DEFAULT TRUE,
    atc_code        VARCHAR(20),    -- WHO ATC classification
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, drug_code)
);

-- Prescriptions
CREATE TABLE prescriptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    rx_number       VARCHAR(30) NOT NULL,
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    patient_id      UUID NOT NULL,
    prescribed_by   UUID NOT NULL,
    prescribed_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status          VARCHAR(20) NOT NULL DEFAULT 'active',
    -- 'active','dispensed','partially_dispensed','cancelled','expired'
    valid_until     TIMESTAMPTZ,
    refills_allowed SMALLINT DEFAULT 0,
    refills_used    SMALLINT DEFAULT 0,
    notes           TEXT,
    UNIQUE (tenant_id, rx_number)
);

CREATE TABLE prescription_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    prescription_id UUID NOT NULL REFERENCES prescriptions(id),
    drug_id         UUID NOT NULL REFERENCES drugs(id),
    dose            VARCHAR(50) NOT NULL,       -- '500mg'
    frequency       VARCHAR(50) NOT NULL,       -- 'TID','BID','QD','PRN'
    route           VARCHAR(30) NOT NULL,       -- 'oral','IV'
    duration_days   SMALLINT,
    quantity        NUMERIC(8,2) NOT NULL,
    unit            VARCHAR(20),                -- 'tablets','ml','vials'
    instructions    TEXT,                       -- 'Take with food'
    indication      TEXT,
    is_substitutable BOOLEAN DEFAULT TRUE,
    dispensing_notes TEXT
);

-- Medication administration record (MAR) — for inpatients
CREATE TABLE medication_administration (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    prescription_item_id UUID NOT NULL REFERENCES prescription_items(id),
    encounter_id    UUID NOT NULL,
    patient_id      UUID NOT NULL,
    scheduled_at    TIMESTAMPTZ NOT NULL,
    administered_at TIMESTAMPTZ,
    administered_by UUID,
    status          VARCHAR(20) NOT NULL DEFAULT 'scheduled',
    -- 'scheduled','administered','held','refused','not_given'
    actual_dose     VARCHAR(50),
    route           VARCHAR(30),
    site            VARCHAR(50),  -- injection site
    hold_reason     VARCHAR(200),
    notes           TEXT,
    witnessed_by    UUID   -- for controlled substances
);
```

---

## 6. PHARMACY INVENTORY MANAGEMENT

```sql
-- Supplier master
CREATE TABLE suppliers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(200) NOT NULL,
    code            VARCHAR(30) NOT NULL,
    contact_person  VARCHAR(100),
    phone           VARCHAR(20),
    email           VARCHAR(100),
    address         JSONB,
    payment_terms   VARCHAR(50),
    lead_time_days  SMALLINT,
    is_active       BOOLEAN DEFAULT TRUE,
    rating          NUMERIC(2,1) CHECK (rating BETWEEN 0 AND 5),
    UNIQUE (tenant_id, code)
);

-- Pharmacy locations/stores
CREATE TABLE pharmacy_stores (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(100) NOT NULL,
    code            VARCHAR(20) NOT NULL,
    department_id   UUID,
    store_type      VARCHAR(20) DEFAULT 'main',  -- 'main','satellite','ward','opd'
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, code)
);

-- Drug inventory (per store, per batch)
CREATE TABLE drug_inventory (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    drug_id         UUID NOT NULL REFERENCES drugs(id),
    store_id        UUID NOT NULL REFERENCES pharmacy_stores(id),
    batch_number    VARCHAR(50) NOT NULL,
    lot_number      VARCHAR(50),
    manufacturer    VARCHAR(200),
    manufactured_date DATE,
    expiry_date     DATE NOT NULL,
    quantity_in_stock NUMERIC(12,3) NOT NULL DEFAULT 0,
    unit            VARCHAR(20) NOT NULL,         -- 'tablets','ml','vials'
    reorder_level   NUMERIC(10,3) NOT NULL DEFAULT 0,
    reorder_quantity NUMERIC(10,3),
    cost_price      NUMERIC(10,4) NOT NULL,        -- per unit
    selling_price   NUMERIC(10,4),
    location_in_store VARCHAR(50),   -- shelf/bin location
    is_quarantined  BOOLEAN DEFAULT FALSE,
    quarantine_reason TEXT,
    received_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, drug_id, store_id, batch_number),
    CONSTRAINT non_negative_stock CHECK (quantity_in_stock >= 0)
);

-- Inventory transactions (every stock movement)
CREATE TABLE inventory_transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    inventory_id    UUID NOT NULL REFERENCES drug_inventory(id),
    transaction_type VARCHAR(30) NOT NULL,
    -- 'purchase_receipt','dispensing','return_from_patient','return_to_supplier',
    -- 'adjustment','transfer_out','transfer_in','expiry_write_off','damage_write_off'
    quantity        NUMERIC(12,3) NOT NULL,  -- negative for outgoing
    quantity_before NUMERIC(12,3) NOT NULL,
    quantity_after  NUMERIC(12,3) NOT NULL,
    reference_type  VARCHAR(30),   -- 'prescription','purchase_order','transfer'
    reference_id    UUID,
    unit_cost       NUMERIC(10,4),
    performed_by    UUID NOT NULL,
    performed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT,
    batch_number    VARCHAR(50)
);

-- Purchase orders
CREATE TABLE purchase_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    po_number       VARCHAR(30) NOT NULL,
    supplier_id     UUID NOT NULL REFERENCES suppliers(id),
    store_id        UUID NOT NULL REFERENCES pharmacy_stores(id),
    status          VARCHAR(20) NOT NULL DEFAULT 'draft',
    -- 'draft','submitted','approved','partially_received','received','cancelled'
    ordered_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expected_at     TIMESTAMPTZ,
    total_amount    NUMERIC(12,2),
    currency        CHAR(3) DEFAULT 'USD',
    approved_by     UUID,
    approved_at     TIMESTAMPTZ,
    notes           TEXT,
    UNIQUE (tenant_id, po_number)
);

CREATE TABLE purchase_order_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    po_id           UUID NOT NULL REFERENCES purchase_orders(id),
    drug_id         UUID NOT NULL REFERENCES drugs(id),
    quantity_ordered NUMERIC(12,3) NOT NULL,
    quantity_received NUMERIC(12,3) DEFAULT 0,
    unit            VARCHAR(20) NOT NULL,
    unit_cost       NUMERIC(10,4) NOT NULL,
    total_cost      NUMERIC(12,2) GENERATED ALWAYS AS (quantity_ordered * unit_cost) STORED,
    expiry_date     DATE
);

-- Alerts view: expiring and low stock
CREATE VIEW drug_alerts AS
SELECT
    di.tenant_id,
    d.drug_code,
    d.generic_name,
    ps.name AS store_name,
    di.batch_number,
    di.expiry_date,
    di.quantity_in_stock,
    di.reorder_level,
    CASE
        WHEN di.expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN di.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        WHEN di.quantity_in_stock <= di.reorder_level THEN 'LOW_STOCK'
        WHEN di.quantity_in_stock = 0 THEN 'OUT_OF_STOCK'
    END AS alert_type
FROM drug_inventory di
JOIN drugs d ON d.id = di.drug_id
JOIN pharmacy_stores ps ON ps.id = di.store_id
WHERE di.quantity_in_stock <= di.reorder_level 
   OR di.expiry_date <= CURRENT_DATE + INTERVAL '30 days';
```

---

## 9. FINANCE & BILLING

```sql
CREATE TABLE service_catalog (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    service_code    VARCHAR(30) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    category        VARCHAR(50),    -- 'consultation','procedure','lab','radiology','room_charge'
    base_price      NUMERIC(10,2) NOT NULL,
    currency        CHAR(3) DEFAULT 'USD',
    is_taxable      BOOLEAN DEFAULT FALSE,
    tax_rate        NUMERIC(5,2) DEFAULT 0,
    insurance_code  VARCHAR(20),   -- CPT code
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, service_code)
);

CREATE TABLE bills (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    bill_number     VARCHAR(30) NOT NULL,
    encounter_id    UUID REFERENCES encounters(id),
    patient_id      UUID NOT NULL,
    bill_type       VARCHAR(20) DEFAULT 'standard',  -- 'standard','insurance','corporate'
    status          VARCHAR(20) NOT NULL DEFAULT 'draft',
    -- 'draft','finalized','partially_paid','paid','waived','disputed','bad_debt'
    subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(12,2) DEFAULT 0,
    tax_amount      NUMERIC(12,2) DEFAULT 0,
    total_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
    paid_amount     NUMERIC(12,2) DEFAULT 0,
    balance_due     NUMERIC(12,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    currency        CHAR(3) DEFAULT 'USD',
    billed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date        TIMESTAMPTZ,
    insurance_id    UUID REFERENCES patient_insurance(id),
    insurance_claim_number VARCHAR(50),
    notes           TEXT,
    UNIQUE (tenant_id, bill_number)
);

CREATE TABLE bill_line_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    bill_id         UUID NOT NULL REFERENCES bills(id),
    service_id      UUID REFERENCES service_catalog(id),
    description     VARCHAR(300) NOT NULL,
    quantity        NUMERIC(8,3) NOT NULL DEFAULT 1,
    unit_price      NUMERIC(10,2) NOT NULL,
    discount_pct    NUMERIC(5,2) DEFAULT 0,
    tax_rate        NUMERIC(5,2) DEFAULT 0,
    line_total      NUMERIC(12,2) NOT NULL,
    service_date    DATE,
    reference_id    UUID,   -- lab_request_id, encounter_id, etc.
    reference_type  VARCHAR(30)
);

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    payment_number  VARCHAR(30) NOT NULL,
    bill_id         UUID NOT NULL REFERENCES bills(id),
    patient_id      UUID NOT NULL,
    amount          NUMERIC(12,2) NOT NULL,
    payment_method  VARCHAR(30) NOT NULL,  -- 'cash','card','bank_transfer','insurance','mobile_money'
    status          VARCHAR(20) DEFAULT 'completed',  -- 'pending','completed','reversed'
    paid_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    received_by     UUID NOT NULL,
    reference_number VARCHAR(100),  -- bank ref, card auth code
    notes           TEXT,
    UNIQUE (tenant_id, payment_number)
);
```

---

## 10. HR & STAFF MANAGEMENT

```sql
CREATE TABLE staff (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    staff_number    VARCHAR(30) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    role            VARCHAR(50) NOT NULL,
    -- 'doctor','nurse','lab_tech','pharmacist','radiologist','admin','finance'
    department_id   UUID,
    specialization  VARCHAR(100),
    license_number  VARCHAR(50),
    license_expiry  DATE,
    phone           VARCHAR(20),
    email           VARCHAR(255),
    employment_type VARCHAR(20) DEFAULT 'full_time',  -- 'full_time','part_time','contract','locum'
    start_date      DATE NOT NULL,
    end_date        DATE,
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, staff_number)
);

CREATE TABLE shifts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(50) NOT NULL,  -- 'Morning','Afternoon','Night'
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    department_id   UUID
);

CREATE TABLE staff_schedules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    staff_id        UUID NOT NULL REFERENCES staff(id),
    shift_id        UUID NOT NULL REFERENCES shifts(id),
    schedule_date   DATE NOT NULL,
    status          VARCHAR(20) DEFAULT 'scheduled',
    -- 'scheduled','attended','absent','on_leave','swapped'
    checked_in_at   TIMESTAMPTZ,
    checked_out_at  TIMESTAMPTZ,
    notes           TEXT,
    UNIQUE (tenant_id, staff_id, schedule_date, shift_id)
);

CREATE TABLE leave_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    staff_id        UUID NOT NULL REFERENCES staff(id),
    leave_type      VARCHAR(30) NOT NULL,  -- 'annual','sick','maternity','unpaid','emergency'
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    days_requested  SMALLINT GENERATED ALWAYS AS 
                    (end_date - start_date + 1) STORED,
    reason          TEXT,
    status          VARCHAR(20) DEFAULT 'pending',
    approved_by     UUID,
    approved_at     TIMESTAMPTZ,
    rejection_reason TEXT
);
```

---

## 12. Healthcare-Specific Notes

### Compliance Flags
- **HIPAA (US):** All PHI columns must be encrypted at rest. Use PostgreSQL `pgcrypto` or TDE. Audit every access to patient records.
- **HL7 FHIR:** Design resource IDs to be FHIR-compatible (UUIDs). Structure `JSONB` fields to mirror FHIR resource shapes for easier interoperability.
- **Critical value notification:** Lab critical results must trigger immediate workflow. Never let `is_critical = TRUE` results stay unacknowledged > 30 min without escalation.
- **Medication safety:** Always check drug-drug interactions at prescription time. Store interaction result in `prescription_items.dispensing_notes`.

### Performance for High-Volume Healthcare DBs
```sql
-- Partition vital_signs by month (can be millions of rows)
CREATE TABLE vital_signs PARTITION BY RANGE (recorded_at);
CREATE TABLE vital_signs_2024_01 PARTITION OF vital_signs
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Partition inventory_transactions by quarter
CREATE TABLE inventory_transactions PARTITION BY RANGE (performed_at);
```
