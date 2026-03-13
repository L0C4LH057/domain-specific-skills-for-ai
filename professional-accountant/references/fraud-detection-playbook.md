# Fraud Detection Playbook & Internal Controls

> Sources: ACFE Report to the Nations 2024, COSO Internal Control — Integrated Framework 2013,
> IIA (Institute of Internal Auditors), ISACA, Big 4 Fraud Risk Management Guides

---

## The Fraud Triangle

Every fraud requires three elements (Cressey, 1953):
```
           PRESSURE
          /         \
         /           \
   OPPORTUNITY ─── RATIONALIZATION
```

- **Pressure**: financial need, debt, lifestyle, gambling, family pressure
- **Opportunity**: weak controls, trusted position, no oversight, complex systems
- **Rationalization**: "I deserve it," "I'll pay it back," "The company can afford it"

Remove any one element → fraud becomes significantly less likely.

---

## Red Flags by Department

### Procurement / Accounts Payable
- [ ] Invoices from vendors not in the approved vendor master list
- [ ] Vendor addresses match employee addresses or PO boxes
- [ ] Round number invoices (₦500,000.00 exactly — real costs are rarely round)
- [ ] Split invoices just below approval thresholds
- [ ] Same invoice number paid more than once
- [ ] Vendor with no physical address, phone, or web presence
- [ ] Payments made to personal bank accounts instead of business accounts
- [ ] Purchase orders raised after goods received (retroactive POs)
- [ ] Frequent sole-source purchases to the same vendor
- [ ] Missing or altered GRNs (Goods Received Notes)
- [ ] Sudden increase in purchases from a specific vendor
- [ ] Vendor not subject to withholding tax but should be

### Payroll
- [ ] Employees with no Bank Verification Number (Nigeria) or equivalent ID
- [ ] Salaries paid to accounts not in employees' names
- [ ] Employee on payroll who no longer works there (ghost employee)
- [ ] Multiple employees sharing the same bank account
- [ ] Unusual mid-month salary adjustments (not authorized by HR)
- [ ] Overtime payments that exceed basic salary
- [ ] Employees with no leave records (may indicate they don't actually exist)
- [ ] Payroll headcount doesn't match HR headcount
- [ ] Staff advances repeatedly approved for same individual

### Cash & Petty Cash
- [ ] Cash receipts not matched to daily sales records
- [ ] Frequent "voids" or "refunds" in POS/till records
- [ ] Petty cash always at maximum limit before replenishment
- [ ] Petty cash expenses with no receipts or doctored receipts
- [ ] The same person who handles cash also records it (no segregation)
- [ ] Large cash withdrawals with vague descriptions ("miscellaneous")
- [ ] Repeated small withdrawals just below scrutiny thresholds

### Revenue / Sales
- [ ] Sales discounts not authorized by management
- [ ] Credit notes raised without returned goods
- [ ] Revenue not recorded until later period (lapping — using new receipts to cover old theft)
- [ ] Customer complaints about payments they made that weren't applied
- [ ] Sales representative with unusually high return rates
- [ ] Invoices raised and quickly reversed with no explanation
- [ ] Revenue concentrated in last few days of month/quarter (manipulation to hit targets)

### Expense Claims
- [ ] Receipts from the same restaurant/hotel for same person, different amounts (padding)
- [ ] Expense claims with printed receipts that look altered
- [ ] Claims for expenses on weekends or public holidays (when was the business meeting?)
- [ ] Claims approved by the same manager repeatedly without review
- [ ] Missing original receipts (only copies submitted)
- [ ] Expenses claimed for assets already provided by company (claiming home internet when company pays)

---

## Internal Control Checklist

### Segregation of Duties (the golden rule)
No single person should control all of:
- Authorization of transactions
- Recording of transactions
- Custody of assets

**Minimum segregation requirements:**

| Function | Person A | Person B |
|---|---|---|
| Raise purchase order | ✓ | |
| Approve purchase order | | ✓ |
| Receive goods (sign GRN) | ✓ | |
| Process payment | | ✓ |
| Sign cheque / authorize transfer | ✓ + Director sign-off | |

### Bank Controls
- [ ] Bank reconciliation performed by someone who doesn't handle cash
- [ ] Bank statements received directly by CFO / Director (not via accountant first)
- [ ] All bank accounts formally listed and approved by board
- [ ] Bank signatories reviewed annually
- [ ] Online banking with dual authorization enabled
- [ ] Transaction alerts set up for all accounts

### Authorization Matrix (example)
| Transaction Type | Up to ₦100K | ₦100K–₦500K | ₦500K–₦5M | Above ₦5M |
|---|---|---|---|---|
| Petty cash | Supervisor | — | — | — |
| Vendor payments | Finance Mgr | Finance Mgr + GM | GM + Director | Board resolution |
| Payroll | Finance Mgr | Finance Mgr | Finance + MD | — |
| Capex | Finance Mgr | GM | MD | Board |
| Loans / financing | — | — | MD + Director | Board resolution |

### IT / System Controls
- [ ] User access reviewed quarterly — no active accounts for ex-staff
- [ ] Admin rights restricted to IT only (not accounts staff)
- [ ] System logs changes to master data (vendor bank accounts, salary amounts)
- [ ] Passwords changed every 90 days; no shared passwords
- [ ] Backup of accounting data performed daily
- [ ] Accounting software requires dual approval for journal entries above threshold

---

## Fraud Investigation Protocol

When fraud is suspected:

### Step 1 — Preserve evidence (do not alert suspect)
- Secure access to accounting system (change passwords quietly)
- Copy all relevant transaction records
- Secure physical documents

### Step 2 — Preliminary assessment (48 hours)
- Calculate estimated amount involved
- Identify all transactions, periods, and parties
- Determine if external parties (vendors, customers) are involved

### Step 3 — Engage experts
- Internal Audit (if independent enough)
- External forensic accountants for significant fraud
- Legal counsel for potential criminal referral
- HR for employment law compliance

### Step 4 — Formal investigation
- Interview witnesses (not suspect — yet)
- Trace all transactions through bank statements
- Compare vendor records to registration databases
- Check employee relationships to vendors

### Step 5 — Report and remediate
- Formal investigation report to board/audit committee
- Disciplinary action per employment contract
- Civil and/or criminal action as appropriate
- Fix the control gap that enabled the fraud

---

## Minimum Internal Control Pack for an SME

Even a 10-person company needs:
1. **Purchase Order** template (raised before any purchase)
2. **Expense Claim Form** with receipt attachment requirement
3. **Bank Reconciliation** — weekly minimum
4. **Petty Cash Book** with daily balance, signed by custodian
5. **Fixed Asset Register** — physical verification annually
6. **Payroll Authorization Sheet** — signed by MD monthly
7. **Vendor Registration Form** — KYC before adding to system
8. **Month-end Checklist** — all reconciliations signed off

---

*Sources: ACFE Report to the Nations 2024 (acfe.com), COSO Internal Control — Integrated
Framework 2013, IIA Global Internal Audit Standards 2024, ISACA COBIT 2019,
PwC Global Economic Crime and Fraud Survey 2024, KPMG Fraud Risk Management Guide.*

---

# IFRS Quick Reference Guide

> Sources: IASB (ifrs.org), ACCA Financial Reporting, Deloitte IAS Plus (iasplus.com)

---

## Key Standards at a Glance

| Standard | Topic | Key Principle |
|---|---|---|
| IAS 1 | Presentation of Financial Statements | Fair presentation; going concern; accruals basis |
| IAS 2 | Inventories | Lower of cost and NRV; FIFO or weighted average (no LIFO under IFRS) |
| IAS 7 | Statement of Cash Flows | Direct or indirect method; classify as operating/investing/financing |
| IAS 8 | Accounting Policies, Errors | Consistency; disclose changes; prior period errors retrospectively restated |
| IAS 10 | Events After Reporting Date | Adjusting vs. non-adjusting events |
| IAS 12 | Income Taxes | Deferred tax using temporary differences; balance sheet liability method |
| IAS 16 | Property, Plant & Equipment | Cost model or revaluation model; depreciate over useful life |
| IAS 19 | Employee Benefits | Defined benefit vs. defined contribution; actuarial valuation |
| IAS 21 | Foreign Currency | Functional vs. presentation currency; retranslation at closing rate |
| IAS 36 | Impairment of Assets | Test annually (goodwill); impair if CA > recoverable amount |
| IAS 37 | Provisions & Contingencies | Recognize if probable outflow + reliable estimate; disclose contingent liabilities |
| IAS 38 | Intangible Assets | Recognize only if identifiable, controllable, probable future benefit |
| IAS 40 | Investment Property | Cost model or fair value model; no depreciation if fair value model |
| IFRS 9 | Financial Instruments | Classification, measurement, ECL (expected credit losses), hedge accounting |
| IFRS 15 | Revenue from Contracts | 5-step model: identify contract → PO → price → allocate → recognize |
| IFRS 16 | Leases | All leases on-balance-sheet (ROU asset + lease liability) for lessees |
| IFRS 17 | Insurance Contracts | For insurance companies — complex measurement model |
| IFRS 10 | Consolidated Financial Statements | Control model for consolidation |

---

## IFRS 15 — Revenue Recognition (5-Step Model)

```
Step 1: Identify the CONTRACT with the customer
         ↓ (Written, oral, or implied; creates enforceable rights)
Step 2: Identify the PERFORMANCE OBLIGATIONS
         ↓ (Distinct goods or services promised)
Step 3: Determine the TRANSACTION PRICE
         ↓ (Fixed, variable, non-cash, financing component?)
Step 4: ALLOCATE the price to performance obligations
         ↓ (Based on relative standalone selling prices)
Step 5: RECOGNIZE revenue when/as PO is SATISFIED
         ↓ (At a point in time OR over time?)
```

**Over time criteria** (any one = over time recognition):
- Customer simultaneously receives and consumes benefits
- Entity's performance creates/enhances an asset customer controls
- Entity's performance has no alternative use AND entity has right to payment for work to date

---

## IFRS 16 — Leases (Simplified)

**Lessee accounting:**
1. At commencement: recognize **Right-of-Use (ROU) Asset** and **Lease Liability**
2. Lease Liability = PV of future lease payments (discounted at implicit rate or IBR)
3. ROU Asset = Lease Liability + initial direct costs + prepayments
4. Depreciate ROU Asset over lease term; unwind interest on Lease Liability
5. **Exemptions**: short-term leases (≤12 months) and low-value assets (< $5,000) — expense straight-line

**P&L impact**: Depreciation (operating) + Interest (finance) replaces rent expense.
**Cash flow impact**: Principal repayments → financing activities (not operating).

---

*Sources: IASB (ifrs.org), ACCA Advanced Financial Reporting, Deloitte IAS Plus,
KPMG Insights into IFRS 2024/25, PwC IFRS Manual of Accounting 2024.*
