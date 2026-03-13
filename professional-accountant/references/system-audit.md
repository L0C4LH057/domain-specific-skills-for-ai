# Accounting System Audit & Redesign Reference

## Phase 1: Discovery — Understand the Current System

### Diagnostic Interview Questions

**Books & Records**
- Are books kept manually (cashbook, ledger) or in software?
- If software: Which one? What version? Is it cloud-based or desktop?
- How far back do clean records go?
- Are there backups? Where?

**Staffing**
- Who currently handles bookkeeping / accounting?
- Is there a dedicated accountant or does the owner handle it?
- What is the finance team size and qualifications?

**Processes**
- How are sales recorded? (invoice book, POS, software?)
- How are purchases recorded? (receipts filed? purchase orders used?)
- How is payroll processed?
- How is bank reconciliation done?
- When were financial statements last produced?
- Is there a budget? Is it tracked?

**Compliance**
- Is the business VAT/GST registered? Are returns filed on time?
- Is PAYE filed and remitted monthly?
- Is the company up to date on corporate income tax filing?
- Have statutory accounts been filed (where required)?
- Any outstanding assessments or disputes with tax authority?

---

## Phase 2: Assessment — Score the Current System

Rate each area 1–5 (1 = broken / missing, 5 = excellent):

| Area | Score | Notes |
|------|-------|-------|
| Chart of accounts (CoA) quality | | |
| Transaction recording accuracy | | |
| Bank reconciliation timeliness | | |
| Accounts receivable management | | |
| Accounts payable management | | |
| Payroll accuracy & compliance | | |
| Tax filing compliance | | |
| Financial reporting quality | | |
| Internal controls / segregation | | |
| Budgeting & forecasting | | |

**Priority matrix**:
- Score 1–2: Fix immediately (critical risk)
- Score 3: Improve within 90 days
- Score 4–5: Maintain and optimize

---

## Phase 3: Redesign — Build the New System

### Stage 1: Foundation (Week 1–2)
1. **Clean or rebuild Chart of Accounts**
   - Match CoA to industry and company size
   - Ensure every expense category is tracked separately
   - Create cost centres if multi-location or multi-project

2. **Set up bank account architecture**
   - Operating, Tax Reserve, Payroll, Savings (as appropriate)
   - Get online banking access for all accounts
   - Set up dual authorization for payments above threshold

3. **Choose/implement accounting software**
   - See `software-guide.md` for recommendations by size/country

### Stage 2: Data Entry & Cleanup (Week 2–4)
1. **Opening balances**: Establish a clean start date
   - Enter all asset balances (cash, debtors, inventory, fixed assets)
   - Enter all liability balances (loans, creditors, tax payables)
   - Calculate equity as the balancing figure
2. **Back-enter critical transactions** if prior period data needed
3. **Reconcile opening bank balance** to statement

### Stage 3: Processes & Procedures (Week 3–6)
Write Standard Operating Procedures (SOPs) for:
- **Sales process**: Quote → Invoice → Receipt → Bank recording
- **Purchase process**: Request → PO → GRN → Invoice → Payment
- **Petty cash**: Float → Disbursement → Voucher → Reconciliation → Top-up
- **Payroll**: HR confirmation → Computation → Approval → Payment → Filing
- **Month-end close**: 10-step checklist (see below)

### Stage 4: Reporting & Governance (Week 4–8)
1. Set up monthly management accounts template:
   - Income Statement (P&L) — actual vs budget vs prior year
   - Balance Sheet — at month-end
   - Cash Flow Statement — direct method preferred for SMEs
   - Key ratios dashboard
   - Aged debtors and creditors summary

2. Schedule monthly finance meetings with business owner/board
3. Set up quarterly tax review calendar

---

## Month-End Close Checklist (10 Steps)

| # | Step | Owner | Target Date |
|---|------|-------|-------------|
| 1 | Post all sales invoices for the month | Accounts Receivable | Day 1 |
| 2 | Post all purchase invoices received | Accounts Payable | Day 1 |
| 3 | Process all bank transactions (not yet posted) | Bookkeeper | Day 2 |
| 4 | Reconcile all bank accounts | Finance Officer | Day 3 |
| 5 | Reconcile petty cash | Finance Officer | Day 3 |
| 6 | Post payroll journal | HR / Finance | Day 3 |
| 7 | Post depreciation journal | Accountant | Day 4 |
| 8 | Post accruals and prepayments | Accountant | Day 4 |
| 9 | Review trial balance for anomalies | Accountant | Day 5 |
| 10 | Produce management accounts; submit to MD | Accountant | Day 7 |

---

## Common Journal Entries Reference

### Depreciation (Monthly)
```
Dr  Depreciation Expense              [P&L]
Cr  Accumulated Depreciation — [Asset]  [Balance Sheet]

Straight-line: Cost ÷ Useful Life (years) ÷ 12 per month
Reducing balance: NBV × Rate% ÷ 12 per month
```

### Accrued Expense (month-end)
```
Dr  [Expense Account]                [P&L]
Cr  Accrued Expenses / Accruals     [Balance Sheet — Current Liability]
```

### Prepaid Expense (e.g., annual insurance paid upfront)
```
On payment:
Dr  Prepaid Expenses                 [Balance Sheet — Current Asset]
Cr  Bank / Cash                      [Balance Sheet]

Monthly amortization:
Dr  Insurance Expense               [P&L]
Cr  Prepaid Expenses                [Balance Sheet]
```

### VAT on Sales (Tax Point)
```
Dr  Accounts Receivable / Bank      [amount including VAT]
Cr  Revenue / Sales                 [net amount]
Cr  VAT Control Account             [VAT amount]
```

### VAT on Purchases
```
Dr  Purchases / Expense             [net amount]
Dr  VAT Control Account             [VAT amount — input tax]
Cr  Accounts Payable / Bank         [gross amount]
```

### VAT Remittance
```
If Output VAT > Input VAT (pay to authority):
Dr  VAT Control Account
Cr  Bank

If Input VAT > Output VAT (refund due):
Dr  VAT Refund Receivable
Cr  VAT Control Account
```

### Payroll Journal
```
Dr  Salaries & Wages Expense        [gross pay]
Cr  PAYE Payable                    [tax deducted]
Cr  Pension Payable (employee)      [employee pension]
Cr  NHF / NHIS Payable             [other deductions]
Cr  Bank / Salaries Payable         [net pay]

Employer pension contribution:
Dr  Pension Expense (employer)      [employer portion]
Cr  Pension Payable                 [employer portion]
```

### Fixed Asset Purchase
```
Dr  Fixed Asset — [Category]        [cost]
Cr  Bank / Accounts Payable         [cost]
```

### Loan Receipt
```
Dr  Bank
Cr  Loan Payable — [Lender Name]
```

### Loan Repayment
```
Dr  Loan Payable (principal portion)
Dr  Interest Expense (interest portion)
Cr  Bank
```

### Director Loan / Drawing
```
Owner withdrawing funds (properly documented):
Dr  Director Loan Account / Drawings
Cr  Bank

Repayment:
Dr  Bank
Cr  Director Loan Account
```

---

## Accounting Software Selection Matrix

| Software | Best For | Countries | Cost |
|----------|----------|-----------|------|
| **QuickBooks Online** | SMEs, service businesses | Global (US, UK, NG, GH, KE) | $$ |
| **Sage 50 / Sage Business Cloud** | SMEs, Manufacturing | UK, ZA, NG, GH, KE | $$ |
| **Xero** | Small-medium, cloud-first | UK, AUS, NZ, Global | $$ |
| **Wave** | Micro-business, freelancers | US, CA, UK, NG | Free |
| **Odoo** | Mid-large, ERP needs | Global | $$–$$$ |
| **SAP Business One** | Large SME, enterprise | Global | $$$$ |
| **QuickBooks Desktop** | Complex Nigerian/African environments with poor internet | NG, GH | $$ |
| **Tally ERP** | Manufacturing, inventory-heavy | NG, GH, KE, ZA, India | $$ |
| **ERPNext** | Open source ERP | Global | Free–$$ |
| **Brightpearl** | Retail / ecommerce multi-channel | UK, US | $$$ |

**Key factors to consider**:
- Internet reliability (cloud vs desktop)
- Multi-currency capability (critical for Nigeria, Kenya import businesses)
- VAT/tax filing integration with local authority
- Payroll module availability for local statutory requirements
- Cost per user/month vs company budget
