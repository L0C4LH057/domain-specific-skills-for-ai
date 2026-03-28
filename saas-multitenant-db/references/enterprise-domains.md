# Enterprise Domains — Non-Healthcare SaaS Verticals

## TOC
1. Education Management System (LMS + SIS)
2. Finance / Accounting ERP (GL, AP, AR, Payroll)
3. Logistics & Supply Chain Management
4. Legal Case Management
5. Manufacturing & ERP
6. Real Estate & Property Management
7. E-Commerce & Retail Platform
8. Field Service Management
9. HR & Payroll Platform (standalone)
10. Construction & Project Management

All tables assume shared-schema multi-tenancy with `tenant_id` on every table.

---

## 1. EDUCATION MANAGEMENT SYSTEM

```sql
-- Academic institutions, schools, campuses
CREATE TABLE academic_institutions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(200) NOT NULL,
    type            VARCHAR(30),  -- 'university','college','k12','vocational'
    accreditation   VARCHAR(100),
    address         JSONB,
    contact         JSONB,
    academic_year_start_month SMALLINT DEFAULT 9
);

CREATE TABLE academic_years (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    year_label      VARCHAR(20) NOT NULL,   -- '2024-2025'
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    is_current      BOOLEAN DEFAULT FALSE
);

CREATE TABLE terms (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    academic_year_id UUID NOT NULL,
    name            VARCHAR(50) NOT NULL,   -- 'Fall 2024','Spring 2025'
    term_type       VARCHAR(20),            -- 'semester','quarter','trimester'
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    registration_open_at  TIMESTAMPTZ,
    registration_close_at TIMESTAMPTZ,
    grades_due_at   TIMESTAMPTZ
);

CREATE TABLE programs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    code            VARCHAR(20) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    degree_type     VARCHAR(30),   -- 'BSc','MSc','PhD','Diploma','Certificate'
    department      VARCHAR(100),
    duration_years  NUMERIC(3,1),
    total_credits   NUMERIC(5,1),
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, code)
);

CREATE TABLE courses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    course_code     VARCHAR(20) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    program_id      UUID,
    credits         NUMERIC(3,1) NOT NULL,
    level           VARCHAR(20),   -- 'undergraduate','graduate','postgraduate'
    prerequisites   UUID[],        -- array of course IDs
    description     TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, course_code)
);

CREATE TABLE students (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    student_number  VARCHAR(30) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE,
    gender          VARCHAR(20),
    email           VARCHAR(255),
    phone           VARCHAR(20),
    program_id      UUID,
    enrollment_date DATE NOT NULL,
    expected_graduation DATE,
    status          VARCHAR(20) DEFAULT 'active',
    -- 'active','inactive','suspended','graduated','withdrawn','deferred'
    cumulative_gpa  NUMERIC(4,3),
    total_credits   NUMERIC(5,1) DEFAULT 0,
    financial_hold  BOOLEAN DEFAULT FALSE,
    UNIQUE (tenant_id, student_number)
);

CREATE TABLE enrollments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    student_id      UUID NOT NULL,
    course_id       UUID NOT NULL,
    term_id         UUID NOT NULL,
    section_id      UUID,
    status          VARCHAR(20) DEFAULT 'enrolled',
    -- 'enrolled','waitlisted','dropped','completed','audit'
    enrolled_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dropped_at      TIMESTAMPTZ,
    final_grade     VARCHAR(5),      -- 'A','B+','C','F','W','I'
    grade_points    NUMERIC(3,1),    -- 4.0, 3.7, etc.
    credits_earned  NUMERIC(3,1),
    UNIQUE (tenant_id, student_id, course_id, term_id)
);

-- Fee management
CREATE TABLE fee_structures (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(100) NOT NULL,
    program_id      UUID,
    academic_year_id UUID NOT NULL,
    components      JSONB NOT NULL, -- [{name, amount, is_required, due_date}]
    total_amount    NUMERIC(10,2) NOT NULL
);

CREATE TABLE student_fees (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    student_id      UUID NOT NULL,
    term_id         UUID NOT NULL,
    fee_structure_id UUID,
    total_charged   NUMERIC(10,2) NOT NULL,
    total_paid      NUMERIC(10,2) DEFAULT 0,
    balance         NUMERIC(10,2) GENERATED ALWAYS AS (total_charged - total_paid) STORED,
    status          VARCHAR(20) DEFAULT 'outstanding',
    due_date        DATE
);
```

---

## 2. FINANCE / ACCOUNTING ERP

```sql
-- Chart of Accounts
CREATE TABLE coa_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    account_code    VARCHAR(20) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    account_type    VARCHAR(30) NOT NULL,
    -- 'asset','liability','equity','revenue','expense','contra_asset'
    account_class   VARCHAR(30),  -- 'current_asset','fixed_asset','current_liability', etc.
    parent_id       UUID REFERENCES coa_accounts(id),
    is_header       BOOLEAN DEFAULT FALSE,  -- header accounts don't post
    currency        CHAR(3) DEFAULT 'USD',
    opening_balance NUMERIC(15,2) DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, account_code)
);

-- Fiscal periods
CREATE TABLE fiscal_periods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    period_name     VARCHAR(50) NOT NULL,   -- '2024-01', 'Q1 2024'
    period_type     VARCHAR(10) NOT NULL,   -- 'monthly','quarterly','annual'
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    status          VARCHAR(20) DEFAULT 'open',  -- 'open','closed','locked'
    UNIQUE (tenant_id, period_name)
);

-- Journal Entries (General Ledger)
CREATE TABLE journal_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    je_number       VARCHAR(30) NOT NULL,
    period_id       UUID NOT NULL REFERENCES fiscal_periods(id),
    entry_type      VARCHAR(30) NOT NULL,
    -- 'manual','auto','opening','closing','reversing','accrual'
    description     TEXT NOT NULL,
    reference_type  VARCHAR(30),  -- 'invoice','payment','payroll','depreciation'
    reference_id    UUID,
    currency        CHAR(3) DEFAULT 'USD',
    exchange_rate   NUMERIC(12,6) DEFAULT 1,
    status          VARCHAR(20) DEFAULT 'draft',  -- 'draft','posted','reversed'
    prepared_by     UUID NOT NULL,
    prepared_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    posted_by       UUID,
    posted_at       TIMESTAMPTZ,
    reversal_je_id  UUID REFERENCES journal_entries(id),
    UNIQUE (tenant_id, je_number)
);

CREATE TABLE journal_lines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    je_id           UUID NOT NULL REFERENCES journal_entries(id),
    account_id      UUID NOT NULL REFERENCES coa_accounts(id),
    line_number     SMALLINT NOT NULL,
    description     VARCHAR(300),
    debit           NUMERIC(15,2) DEFAULT 0,
    credit          NUMERIC(15,2) DEFAULT 0,
    cost_center_id  UUID,
    project_id      UUID,
    tax_code        VARCHAR(20),
    CONSTRAINT debit_or_credit CHECK (
        (debit > 0 AND credit = 0) OR (credit > 0 AND debit = 0)
    )
);

-- Ensure JE lines balance (debit = credit)
CREATE OR REPLACE FUNCTION check_je_balance() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT SUM(debit) - SUM(credit) FROM journal_lines WHERE je_id = NEW.je_id) != 0 THEN
        RAISE EXCEPTION 'Journal entry % is not balanced', NEW.je_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Accounts Receivable
CREATE TABLE ar_invoices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    invoice_number  VARCHAR(30) NOT NULL,
    customer_id     UUID NOT NULL,
    invoice_date    DATE NOT NULL,
    due_date        DATE NOT NULL,
    status          VARCHAR(20) DEFAULT 'outstanding',
    -- 'draft','sent','outstanding','partially_paid','paid','overdue','written_off'
    subtotal        NUMERIC(12,2) NOT NULL,
    tax_amount      NUMERIC(12,2) DEFAULT 0,
    discount_amount NUMERIC(12,2) DEFAULT 0,
    total_amount    NUMERIC(12,2) NOT NULL,
    paid_amount     NUMERIC(12,2) DEFAULT 0,
    currency        CHAR(3) DEFAULT 'USD',
    payment_terms   VARCHAR(30),  -- 'NET30','NET60','DUE_ON_RECEIPT'
    UNIQUE (tenant_id, invoice_number)
);

-- Payroll
CREATE TABLE payroll_runs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    pay_period_start DATE NOT NULL,
    pay_period_end  DATE NOT NULL,
    pay_date        DATE NOT NULL,
    status          VARCHAR(20) DEFAULT 'draft',
    -- 'draft','calculated','approved','paid','reversed'
    total_gross     NUMERIC(12,2) DEFAULT 0,
    total_deductions NUMERIC(12,2) DEFAULT 0,
    total_net       NUMERIC(12,2) DEFAULT 0,
    employee_count  INTEGER DEFAULT 0,
    processed_by    UUID,
    approved_by     UUID,
    UNIQUE (tenant_id, pay_period_start, pay_period_end)
);

CREATE TABLE payroll_slips (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    run_id          UUID NOT NULL REFERENCES payroll_runs(id),
    employee_id     UUID NOT NULL,
    basic_salary    NUMERIC(10,2) NOT NULL,
    allowances      JSONB DEFAULT '[]',   -- [{name, amount}]
    deductions      JSONB DEFAULT '[]',   -- [{name, amount, type}]
    gross_pay       NUMERIC(10,2) NOT NULL,
    total_deductions NUMERIC(10,2) NOT NULL DEFAULT 0,
    net_pay         NUMERIC(10,2) NOT NULL,
    tax_amount      NUMERIC(10,2) DEFAULT 0,
    currency        CHAR(3) DEFAULT 'USD',
    bank_account    VARCHAR(30),
    payment_method  VARCHAR(20),
    payment_status  VARCHAR(20) DEFAULT 'pending'
);
```

---

## 3. LOGISTICS & SUPPLY CHAIN

```sql
CREATE TABLE warehouses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    code            VARCHAR(20) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    type            VARCHAR(30),   -- 'main','distribution','transit','cold_storage'
    address         JSONB NOT NULL,
    capacity_cbm    NUMERIC(10,2),  -- cubic meters
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, code)
);

CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    sku             VARCHAR(50) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    category        VARCHAR(100),
    brand           VARCHAR(100),
    unit_of_measure VARCHAR(20) NOT NULL,  -- 'each','kg','liter','carton'
    weight_kg       NUMERIC(8,3),
    dimensions      JSONB,   -- {length_cm, width_cm, height_cm}
    requires_refrigeration BOOLEAN DEFAULT FALSE,
    hazmat          BOOLEAN DEFAULT FALSE,
    reorder_point   NUMERIC(10,3) DEFAULT 0,
    reorder_qty     NUMERIC(10,3),
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, sku)
);

CREATE TABLE inventory_locations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    warehouse_id    UUID NOT NULL,
    aisle           VARCHAR(10),
    rack            VARCHAR(10),
    level           VARCHAR(10),
    bin             VARCHAR(10),
    location_code   VARCHAR(30) NOT NULL,   -- 'A-01-B-03'
    is_active       BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, warehouse_id, location_code)
);

CREATE TABLE stock_levels (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    product_id      UUID NOT NULL,
    warehouse_id    UUID NOT NULL,
    location_id     UUID,
    quantity_on_hand    NUMERIC(12,3) DEFAULT 0,
    quantity_reserved   NUMERIC(12,3) DEFAULT 0,
    quantity_available  NUMERIC(12,3) GENERATED ALWAYS AS 
                        (quantity_on_hand - quantity_reserved) STORED,
    quantity_on_order   NUMERIC(12,3) DEFAULT 0,
    last_counted_at TIMESTAMPTZ,
    UNIQUE (tenant_id, product_id, warehouse_id)
);

CREATE TABLE shipments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    shipment_number VARCHAR(30) NOT NULL,
    type            VARCHAR(20) NOT NULL,   -- 'outbound','inbound','transfer'
    status          VARCHAR(20) NOT NULL DEFAULT 'draft',
    -- 'draft','pending_pickup','in_transit','delivered','exception','returned'
    origin_id       UUID,    -- warehouse_id or external address
    destination_id  UUID,
    carrier         VARCHAR(100),
    tracking_number VARCHAR(100),
    service_level   VARCHAR(30),   -- 'standard','express','overnight','freight'
    scheduled_pickup_at TIMESTAMPTZ,
    actual_pickup_at    TIMESTAMPTZ,
    estimated_delivery  TIMESTAMPTZ,
    actual_delivery_at  TIMESTAMPTZ,
    weight_kg       NUMERIC(8,2),
    total_pieces    INTEGER,
    special_instructions TEXT,
    UNIQUE (tenant_id, shipment_number)
);

CREATE TABLE routes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    route_code      VARCHAR(20) NOT NULL,
    name            VARCHAR(100),
    stops           JSONB NOT NULL,  -- [{location_id, sequence, eta}]
    vehicle_id      UUID,
    driver_id       UUID,
    date            DATE NOT NULL,
    status          VARCHAR(20) DEFAULT 'planned',
    total_distance_km NUMERIC(8,2),
    UNIQUE (tenant_id, route_code)
);
```

---

## 4. LEGAL CASE MANAGEMENT

```sql
CREATE TABLE clients (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    client_number   VARCHAR(30) NOT NULL,
    client_type     VARCHAR(20) NOT NULL,   -- 'individual','company'
    name            VARCHAR(200) NOT NULL,
    contact         JSONB,
    kyc_status      VARCHAR(20) DEFAULT 'pending',  -- 'pending','verified','rejected'
    conflict_check_at TIMESTAMPTZ,
    UNIQUE (tenant_id, client_number)
);

CREATE TABLE matters (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    matter_number   VARCHAR(30) NOT NULL,
    client_id       UUID NOT NULL,
    title           VARCHAR(300) NOT NULL,
    practice_area   VARCHAR(50),  -- 'litigation','corporate','ip','employment','real_estate'
    matter_type     VARCHAR(30),  -- 'advisory','transactional','contentious'
    status          VARCHAR(20) DEFAULT 'open',
    responsible_lawyer UUID NOT NULL,
    team_members    UUID[],
    opened_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMPTZ,
    billing_type    VARCHAR(20),  -- 'hourly','fixed','contingency','retainer'
    hourly_rate     NUMERIC(8,2),
    budget_amount   NUMERIC(12,2),
    court_jurisdiction VARCHAR(100),
    opposing_party  VARCHAR(200),
    UNIQUE (tenant_id, matter_number)
);

CREATE TABLE time_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    matter_id       UUID NOT NULL REFERENCES matters(id),
    staff_id        UUID NOT NULL,
    date            DATE NOT NULL,
    hours           NUMERIC(5,2) NOT NULL,
    description     TEXT NOT NULL,
    activity_code   VARCHAR(20),   -- standardized activity codes (UTBMS)
    task_code       VARCHAR(20),
    hourly_rate     NUMERIC(8,2) NOT NULL,
    amount          NUMERIC(10,2) GENERATED ALWAYS AS (hours * hourly_rate) STORED,
    is_billable     BOOLEAN DEFAULT TRUE,
    status          VARCHAR(20) DEFAULT 'draft',  -- 'draft','approved','billed','written_off'
    invoice_id      UUID
);

CREATE TABLE case_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    matter_id       UUID NOT NULL,
    title           VARCHAR(300) NOT NULL,
    document_type   VARCHAR(50),   -- 'contract','pleading','evidence','correspondence','order'
    file_path       VARCHAR(500),
    file_size_bytes BIGINT,
    version         INTEGER DEFAULT 1,
    status          VARCHAR(20) DEFAULT 'draft',
    is_privileged   BOOLEAN DEFAULT FALSE,
    uploaded_by     UUID NOT NULL,
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE court_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    matter_id       UUID NOT NULL,
    event_type      VARCHAR(50),   -- 'hearing','trial','deposition','filing_deadline'
    title           VARCHAR(200) NOT NULL,
    scheduled_at    TIMESTAMPTZ NOT NULL,
    location        VARCHAR(200),
    judge           VARCHAR(100),
    notes           TEXT,
    outcome         TEXT,
    completed_at    TIMESTAMPTZ
);
```

---

## 5. MANUFACTURING & ERP

```sql
CREATE TABLE bill_of_materials (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    bom_number      VARCHAR(30) NOT NULL,
    product_id      UUID NOT NULL,
    version         INTEGER NOT NULL DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE,
    effective_date  DATE,
    expiry_date     DATE,
    UNIQUE (tenant_id, bom_number, version)
);

CREATE TABLE bom_components (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    bom_id          UUID NOT NULL REFERENCES bill_of_materials(id),
    component_id    UUID NOT NULL,  -- material/product
    quantity        NUMERIC(12,4) NOT NULL,
    unit            VARCHAR(20) NOT NULL,
    scrap_pct       NUMERIC(5,2) DEFAULT 0,  -- waste factor
    is_phantom      BOOLEAN DEFAULT FALSE,    -- phantom BOM level
    level           SMALLINT DEFAULT 1        -- BOM explosion level
);

CREATE TABLE work_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    wo_number       VARCHAR(30) NOT NULL,
    product_id      UUID NOT NULL,
    bom_id          UUID REFERENCES bill_of_materials(id),
    quantity_planned NUMERIC(10,3) NOT NULL,
    quantity_produced NUMERIC(10,3) DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'draft',
    -- 'draft','released','in_progress','completed','cancelled'
    priority        SMALLINT DEFAULT 50,   -- 0-100
    planned_start   TIMESTAMPTZ,
    planned_end     TIMESTAMPTZ,
    actual_start    TIMESTAMPTZ,
    actual_end      TIMESTAMPTZ,
    work_center_id  UUID,
    UNIQUE (tenant_id, wo_number)
);

CREATE TABLE quality_inspections (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    reference_type  VARCHAR(30) NOT NULL,  -- 'work_order','purchase_receipt','in_process'
    reference_id    UUID NOT NULL,
    inspection_type VARCHAR(30),    -- 'incoming','in_process','final'
    status          VARCHAR(20) DEFAULT 'pending',  -- 'pending','passed','failed','conditional'
    inspected_by    UUID,
    inspected_at    TIMESTAMPTZ,
    sample_size     INTEGER,
    defects_found   INTEGER DEFAULT 0,
    defect_details  JSONB,
    disposition     VARCHAR(30),   -- 'accept','reject','rework','scrap'
    notes           TEXT
);
```

---

## 6. REAL ESTATE & PROPERTY MANAGEMENT

```sql
CREATE TABLE properties (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    property_code   VARCHAR(30) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    type            VARCHAR(30),   -- 'residential','commercial','industrial','mixed'
    address         JSONB NOT NULL,
    total_area_sqm  NUMERIC(10,2),
    year_built      SMALLINT,
    owner_id        UUID,
    manager_id      UUID,
    status          VARCHAR(20) DEFAULT 'active',
    amenities       TEXT[],
    UNIQUE (tenant_id, property_code)
);

CREATE TABLE units (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    property_id     UUID NOT NULL,
    unit_number     VARCHAR(20) NOT NULL,
    floor           SMALLINT,
    area_sqm        NUMERIC(8,2),
    bedrooms        SMALLINT,
    bathrooms       NUMERIC(3,1),
    unit_type       VARCHAR(30),   -- 'studio','1bed','2bed','office','retail'
    status          VARCHAR(20) DEFAULT 'available',
    -- 'available','occupied','maintenance','reserved'
    monthly_rent    NUMERIC(10,2),
    UNIQUE (tenant_id, property_id, unit_number)
);

CREATE TABLE leases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    lease_number    VARCHAR(30) NOT NULL,
    unit_id         UUID NOT NULL REFERENCES units(id),
    tenant_contact_id UUID NOT NULL,  -- the actual tenant (lessee)
    start_date      DATE NOT NULL,
    end_date        DATE,
    lease_type      VARCHAR(20) DEFAULT 'fixed',  -- 'fixed','month_to_month','commercial'
    monthly_rent    NUMERIC(10,2) NOT NULL,
    deposit_amount  NUMERIC(10,2),
    status          VARCHAR(20) DEFAULT 'active',
    -- 'draft','active','expired','terminated','renewed'
    auto_renew      BOOLEAN DEFAULT FALSE,
    renewal_notice_days SMALLINT DEFAULT 60,
    signed_at       DATE,
    UNIQUE (tenant_id, lease_number)
);

CREATE TABLE maintenance_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    ticket_number   VARCHAR(30) NOT NULL,
    unit_id         UUID NOT NULL,
    reported_by     UUID NOT NULL,
    category        VARCHAR(50),   -- 'plumbing','electrical','hvac','appliance','structural'
    priority        VARCHAR(10) DEFAULT 'normal',  -- 'emergency','high','normal','low'
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    status          VARCHAR(20) DEFAULT 'open',
    -- 'open','assigned','in_progress','completed','cancelled'
    assigned_to     UUID,
    scheduled_at    TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    cost_estimate   NUMERIC(8,2),
    actual_cost     NUMERIC(8,2),
    UNIQUE (tenant_id, ticket_number)
);
```

---

## 8. HR & PAYROLL PLATFORM (Standalone SaaS)

```sql
CREATE TABLE employees (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    employee_number VARCHAR(30) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE,
    gender          VARCHAR(20),
    national_id     VARCHAR(50),
    hire_date       DATE NOT NULL,
    termination_date DATE,
    status          VARCHAR(20) DEFAULT 'active',
    employment_type VARCHAR(20),  -- 'full_time','part_time','contract','intern'
    department_id   UUID,
    job_title_id    UUID,
    manager_id      UUID REFERENCES employees(id),
    work_location   VARCHAR(30),  -- 'office','remote','hybrid','field'
    bank_account    JSONB,         -- encrypted
    tax_id          VARCHAR(50),
    UNIQUE (tenant_id, employee_number)
);

CREATE TABLE compensation (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    employee_id     UUID NOT NULL REFERENCES employees(id),
    effective_date  DATE NOT NULL,
    salary_type     VARCHAR(20) NOT NULL,  -- 'annual','monthly','hourly','daily'
    base_amount     NUMERIC(12,2) NOT NULL,
    currency        CHAR(3) DEFAULT 'USD',
    pay_frequency   VARCHAR(20) DEFAULT 'monthly',
    change_reason   VARCHAR(50),   -- 'hire','promotion','merit','market_adj'
    approved_by     UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE performance_reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    employee_id     UUID NOT NULL,
    reviewer_id     UUID NOT NULL,
    review_period   VARCHAR(30) NOT NULL,  -- 'Q1 2024','Annual 2024'
    review_type     VARCHAR(20),           -- 'annual','quarterly','probation','360'
    status          VARCHAR(20) DEFAULT 'draft',
    overall_rating  NUMERIC(3,1),          -- e.g. 4.2 out of 5
    competencies    JSONB,                 -- [{name, score, comments}]
    goals_achieved  JSONB,
    development_plan TEXT,
    submitted_at    TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ
);

CREATE TABLE benefits (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(30),    -- 'health','dental','vision','retirement','life','other'
    provider        VARCHAR(100),
    coverage_amount NUMERIC(10,2),
    employee_cost   NUMERIC(8,2),
    employer_cost   NUMERIC(8,2),
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE employee_benefits (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    employee_id     UUID NOT NULL REFERENCES employees(id),
    benefit_id      UUID NOT NULL REFERENCES benefits(id),
    enrollment_date DATE NOT NULL,
    end_date        DATE,
    status          VARCHAR(20) DEFAULT 'active',
    dependents      JSONB   -- [{name, relationship, date_of_birth}]
);
```

---

## 10. CONSTRUCTION & PROJECT MANAGEMENT

```sql
CREATE TABLE projects (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    project_code    VARCHAR(30) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    client_id       UUID,
    project_type    VARCHAR(30),   -- 'residential','commercial','infrastructure','renovation'
    status          VARCHAR(20) DEFAULT 'planning',
    -- 'planning','active','on_hold','completed','cancelled'
    contract_amount NUMERIC(15,2),
    budget_amount   NUMERIC(15,2),
    actual_cost     NUMERIC(15,2) DEFAULT 0,
    start_date      DATE,
    planned_end     DATE,
    actual_end      DATE,
    project_manager UUID,
    location        JSONB,
    UNIQUE (tenant_id, project_code)
);

CREATE TABLE tasks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    project_id      UUID NOT NULL REFERENCES projects(id),
    parent_task_id  UUID REFERENCES tasks(id),  -- WBS hierarchy
    task_code       VARCHAR(20),
    name            VARCHAR(200) NOT NULL,
    phase           VARCHAR(50),
    status          VARCHAR(20) DEFAULT 'not_started',
    priority        VARCHAR(10) DEFAULT 'medium',
    assigned_to     UUID,
    start_date      DATE,
    due_date        DATE,
    completed_at    TIMESTAMPTZ,
    estimated_hours NUMERIC(8,2),
    actual_hours    NUMERIC(8,2) DEFAULT 0,
    completion_pct  SMALLINT DEFAULT 0 CHECK (completion_pct BETWEEN 0 AND 100),
    dependencies    UUID[],   -- array of task IDs (must complete before this)
    notes           TEXT
);

CREATE TABLE daily_site_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL,
    project_id      UUID NOT NULL,
    log_date        DATE NOT NULL,
    weather         VARCHAR(50),
    workers_present INTEGER,
    work_performed  TEXT NOT NULL,
    materials_used  JSONB,
    equipment_used  JSONB,
    issues          TEXT,
    photos          TEXT[],   -- storage paths
    submitted_by    UUID NOT NULL,
    submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, project_id, log_date)
);
```
