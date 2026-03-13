# Money Flow Framework — Complete Methodology

> Reference: IAS 7 (Statement of Cash Flows), COSO Internal Control Framework,
> Basel Committee on Banking Supervision, World Bank Financial Management Guidelines

---

## The 7-Circuit Money Map

Every business — from a Lagos market stall to a multinational — moves money
through the same fundamental circuits. Master these and you master the company.

```
╔══════════════════════════════════════════════════════════════╗
║                    THE 7-CIRCUIT MONEY MAP                   ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  [1] REVENUE CIRCUIT                                         ║
║      Customers → Invoices → Collections → Bank               ║
║           ↓                                                  ║
║  [2] OPERATING CIRCUIT                                       ║
║      Bank → Payroll → Suppliers → Overheads → Bank           ║
║           ↓                                                  ║
║  [3] TAX CIRCUIT                                             ║
║      Revenue/Profit → Tax Provision → FIRS/KRA/SARS/HMRC     ║
║           ↓                                                  ║
║  [4] CAPITAL CIRCUIT                                         ║
║      Equity/Loans → Assets → Depreciation → Replacement      ║
║           ↓                                                  ║
║  [5] WORKING CAPITAL CIRCUIT                                 ║
║      Cash → Inventory → Debtors → Cash (cycle time!)         ║
║           ↓                                                  ║
║  [6] FINANCING CIRCUIT                                       ║
║      Banks/Investors → Company → Interest/Dividends → Out    ║
║           ↓                                                  ║
║  [7] PROFIT DISTRIBUTION CIRCUIT                             ║
║      Net Profit → Retained Earnings + Dividends + Reserves   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Circuit 1 — Revenue Circuit (Money Coming IN)

### What to trace:
- **All revenue streams** — product sales, service fees, rental income, commissions,
  grants, subscriptions. Never aggregate — list every single source separately.
- **Invoicing discipline** — Are invoices raised immediately on delivery? Or late?
  Late invoicing = free credit to customers = cash leak.
- **Collection terms** — What are the agreed payment terms (Net 7, Net 30, Net 60)?
  What is the actual average days to collect?
- **Bad debts** — What percentage of invoices are never collected?
  Is an allowance for doubtful debts maintained?

### Key metrics:
| Metric | Formula | Red Flag |
|---|---|---|
| Debtor Days | (Receivables / Revenue) × 365 | >45 days for most businesses |
| Collection Efficiency | Cash Collected / Invoices Raised | <90% signals problem |
| Revenue per Employee | Revenue / Headcount | Declining trend = efficiency issue |
| Revenue Concentration | Top 3 clients / Total Revenue | >50% = dangerous dependency |

### Diagnostic questions:
1. Is there a formal invoicing system or is it manual/WhatsApp-based?
2. Who is authorized to raise an invoice? Is there a price list?
3. Does someone reconcile cash received to invoices raised every day?
4. Are there discounts being given informally (below the table)?
5. Is revenue recognized at the point of invoice or at the point of cash receipt?
   (IFRS 15: recognize when performance obligation is satisfied)

### Common revenue leaks found in African SMEs:
- Sales staff collecting cash and not remitting fully
- Discounts given verbally without documentation
- Revenue earned in foreign currency not converted at correct rate
- Goods returned but credit notes never issued (double-counting revenue)
- Income from side activities (waste sales, scrap) never recorded

---

## Circuit 2 — Operating Circuit (Money Going OUT)

### Categories of operating expenditure:
```
COGS (Cost of Goods Sold)
├── Direct materials / stock purchases
├── Direct labour
└── Direct overheads (factory power, freight)

OPERATING EXPENSES (below gross profit line)
├── Salaries & wages (all staff)
├── Rent & rates
├── Utilities (power, water, internet)
├── Marketing & advertising
├── Professional fees (legal, audit, consulting)
├── Travel & entertainment
├── Repairs & maintenance
├── Bank charges & interest
├── Depreciation
└── Miscellaneous / sundry
```

### Control framework for payments:
Every payment must pass through **4 gates**:
1. **Raise** — Purchase requisition from department head
2. **Approve** — Finance manager or CFO approval (above threshold)
3. **Process** — Accounts payable team verifies invoice vs. PO vs. GRN
4. **Pay** — Bank payment with dual authorization (two signatories)

### Creditor Days optimization:
- Target: negotiate maximum payment terms with suppliers (Net 45–60)
- But: pay on time to protect credit rating and supplier relationships
- Warning: stretching creditors beyond terms damages supplier goodwill and
  can trigger COD (cash on delivery) requirements — a cash crisis trigger

### Common operating circuit failures:
- Petty cash with no limit and no reconciliation
- Staff advances never recovered (become informal salary advances)
- Supplier invoices paid without matching to purchase orders
- Duplicate payments (same invoice paid twice)
- Ghost vendors (payments to companies owned by staff)
- Fuel cards used for personal vehicle fill-ups
- Expired subscriptions still being charged

---

## Circuit 3 — Tax Circuit

> Critical: Tax is NOT optional. It is a legally mandated cash outflow.
> Treating it as such prevents cash crises when assessments arrive.

### Tax provisioning methodology:
Every month, before distributing profit, compute and set aside:

```
Monthly Tax Provision Schedule
─────────────────────────────────
Gross Revenue                    xxx
Less: VAT Collected (liability)  (xxx)    → Set aside in VAT reserve account
Net Revenue                      xxx

Estimated Taxable Profit         xxx
× Applicable CIT Rate            xx%
= Monthly CIT Provision          xxx     → Set aside in tax reserve account

Payroll Processed                xxx
PAYE Deducted                    xxx     → Must be remitted within 10 days (Nigeria)
                                          → Must be remitted by 9th of next month (Kenya)

WHT Deducted on Payments         xxx     → Track by vendor, remit monthly
```

### Tax reserve account:
Open a **dedicated tax reserve bank account** (separate from operating account).
Transfer tax provisions monthly. Never use this money for operations.
This eliminates the "we don't have money for taxes" crisis.

---

## Circuit 4 — Capital Circuit (Fixed Assets)

### Asset register components:
| Field | Description |
|---|---|
| Asset Code | Unique identifier |
| Asset Description | Detailed description |
| Purchase Date | Date of acquisition |
| Cost | Original purchase price |
| Useful Life | Estimated years of use |
| Residual Value | Estimated scrap value at end |
| Depreciation Method | Straight-line or reducing balance |
| Annual Depreciation | Calculated charge to P&L |
| Accumulated Depreciation | Total depreciation to date |
| Net Book Value | Cost less Accumulated Depreciation |
| Location | Physical location |
| Custodian | Staff member responsible |

### Depreciation rates (indicative — confirm local tax rules):
| Asset Class | Straight-Line | Reducing Balance |
|---|---|---|
| Buildings | 2–5% | — |
| Plant & Machinery | 10–25% | 25–33% |
| Motor Vehicles | 20–25% | 25–33% |
| Computer Equipment | 25–33% | 33% |
| Furniture & Fittings | 10–20% | 20% |
| Leasehold Improvements | Over lease term | — |

### Capital replacement fund:
Depreciation is a non-cash charge but represents the consumption of an asset.
Best practice: create a **sinking fund** — transfer an amount equal to
depreciation each month into a dedicated account to fund future replacements.

---

## Circuit 5 — Working Capital Circuit

This is where most SMEs bleed. The **Cash Conversion Cycle (CCC)** measures
how long money is tied up before it returns as cash.

```
CCC = Inventory Days + Debtor Days − Creditor Days
```

**Target: minimize CCC (ideally negative for retail/e-commerce)**

Example:
```
A manufacturing company has:
- Inventory Days: 45
- Debtor Days: 60
- Creditor Days: 30
CCC = 45 + 60 − 30 = 75 days

This means: for every ₦1 million in revenue,
the company needs ₦205,479 in working capital financing.
(₦1M / 365 × 75 = ₦205,479)
```

### Working capital optimization levers:
1. **Reduce inventory** — JIT ordering, minimum stock levels, clearance of slow movers
2. **Accelerate collections** — Early payment discounts, stricter credit terms, daily chasing
3. **Extend payables** — Negotiate longer terms, use credit lines strategically
4. **Invoice financing** — Sell receivables to a bank (factoring) for immediate cash

---

## Circuit 6 — Financing Circuit

### Debt schedule — maintain at all times:
| Lender | Facility Type | Amount | Rate | Monthly Payment | Outstanding | Maturity |
|---|---|---|---|---|---|---|
| Bank A | Term Loan | ₦50M | 22% | ₦1.2M | ₦38M | Dec 2026 |
| Bank B | Overdraft | ₦10M | 26% | Interest only | ₦7M | Revolving |
| Director | Shareholder Loan | ₦5M | 0% | — | ₦5M | Demand |

**Red flags on financing:**
- Interest cost > 15% of revenue (debt burden is crushing the business)
- Overdraft consistently at maximum (business is cash-flow insolvent)
- No formal loan agreements for shareholder/director loans (tax and legal risk)
- Borrowing to pay salaries (existential warning sign)

---

## Circuit 7 — Profit Distribution Circuit

### Retained earnings waterfall:
```
NET PROFIT AFTER TAX
        ↓
[Statutory Reserve]         — 25% of profit (required in some jurisdictions)
        ↓
[Dividend Declaration]      — Requires board resolution; subject to WHT
        ↓
[Retained Earnings]         — Balance stays in business for growth
        ↓
[Bonus / Management Fees]   — Must be at arm's length and documented
```

**Dividend tax obligations:**
- Nigeria: 10% WHT on dividends paid to individuals
- Kenya: 5% WHT (residents), 10% (non-residents)
- Ghana: 8% WHT on dividends
- South Africa: 20% Dividends Tax
- UK: Dividend tax at 8.75% / 33.75% / 39.35% depending on tax band
- USA: Qualified dividends taxed at 0% / 15% / 20%

---

## 13-Week Cash Flow Forecast Template

The 13-week rolling cash flow is the most important management tool for a
business under cash pressure. Update weekly.

```
WEEK                    Wk1    Wk2    Wk3    ...  Wk13
─────────────────────────────────────────────────────
OPENING CASH BALANCE    xxx    xxx    xxx         xxx

INFLOWS
  Customer collections  xxx    xxx    xxx         xxx
  Other income          xxx    xxx    xxx         xxx
  Loan drawdowns        xxx    xxx    xxx         xxx
TOTAL INFLOWS           xxx    xxx    xxx         xxx

OUTFLOWS
  Supplier payments     xxx    xxx    xxx         xxx
  Payroll               xxx    xxx    xxx         xxx
  Rent                  xxx    xxx    xxx         xxx
  Tax remittances       xxx    xxx    xxx         xxx
  Loan repayments       xxx    xxx    xxx         xxx
  Overheads             xxx    xxx    xxx         xxx
TOTAL OUTFLOWS          xxx    xxx    xxx         xxx

NET CASH MOVEMENT       xxx    xxx    xxx         xxx
CLOSING CASH BALANCE    xxx    xxx    xxx         xxx
MINIMUM BALANCE         xxx    xxx    xxx         xxx
VARIANCE TO MINIMUM     xxx    xxx    xxx         xxx
```

**Action rule:** Any week where Closing Balance < Minimum Balance requires
immediate action — either accelerate collections or defer non-critical payments.

---

## Bank Reconciliation Standard

Perform daily for all bank accounts. Never allow a backlog.

```
Balance per Bank Statement              xxx
Add: Deposits in transit               xxx
Less: Outstanding cheques / payments   (xxx)
Add/Less: Bank errors                  xxx
= ADJUSTED BANK BALANCE                xxx

Balance per Cash Book                  xxx
Add: Interest credited by bank         xxx
Less: Bank charges not in books        (xxx)
Less: Returned cheques                 (xxx)
Add/Less: Book errors                  xxx
= ADJUSTED BOOK BALANCE                xxx

THESE TWO MUST AGREE — if not, investigate immediately
```

---

*Sources: IAS 7 (IASB), COSO ERM Framework 2017, World Bank Financial Management
Guidance for Project-Financed Operations, ICAEW Cash Management Toolkit,
ACCA P2 Corporate Reporting, ICAN Professional Study Pack, McKinsey Working
Capital Management Report 2023.*
