# Money Flow Design & Tracing Reference

## The Money Flow Architecture

A healthy company has money flowing through clearly defined channels with controls at each gate. Think of it like plumbing — every pipe must be traceable, every valve must have a controller.

```
MONEY IN                           MONEY HOLDING                     MONEY OUT
─────────────────────────────────────────────────────────────────────────────
Customer Payments                  Main Operating Account            Supplier Payments
Grant Receipts          ──────►    Petty Cash Fund        ──────►   Payroll
Investment Capital                 Savings/Reserve Fund              Tax Remittances
Loan Disbursements                 Foreign Currency Account          Loan Repayments
Asset Sales                        Restricted Accounts               Capital Expenditure
                                                                      Owner Dividends
```

---

## Step 1: Map Current Money Flow

Before redesigning, document where money currently flows. Ask:

1. **Inflows**: How does money enter the business?
   - Cash sales? POS? Bank transfer? Mobile money (M-Pesa, Flutterwave, Paystack)?
   - Multiple revenue streams? Are they all hitting the same account?

2. **Holding points**: Where does money sit?
   - How many bank accounts? What is each for?
   - Is there a petty cash fund? Who controls it?
   - Is there a savings buffer account?

3. **Outflows**: How does money leave?
   - Who approves payments?
   - Are there spending limits?
   - How are suppliers paid? Staff paid?

4. **Reconciliation**: How is money tracked?
   - Daily? Weekly? Monthly?
   - Who reconciles? Who reviews?

---

## Step 2: Diagnose Money Flow Problems

### Common Failure Patterns

**Pattern 1: Single Account Chaos**
All money (income, expenses, payroll, tax savings) flows through one account. 
- *Risk*: Can't distinguish tax liability from available cash; mixing operating and capital funds.
- *Fix*: Multi-account architecture (see below).

**Pattern 2: Cash Leakage**
Cash received but not recorded; petty cash uncontrolled; "informal" payments.
- *Risk*: Revenue understatement, tax fraud exposure, theft.
- *Fix*: Point-of-sale systems, receipt books with serial numbers, imprest petty cash.

**Pattern 3: Owner Extracting Cash Without Records**
Owner takes cash from register or bank for personal use without formal documentation.
- *Risk*: Books don't balance; tax authorities treat it as undeclared income.
- *Fix*: Formal director loan account or dividend declaration process.

**Pattern 4: Accounts Payable Mismanagement**
Paying suppliers without matching to purchase orders/invoices.
- *Risk*: Duplicate payments, overpayments, fraud.
- *Fix*: 3-way match process (PO + GRN + Invoice before payment).

**Pattern 5: Untracked Receivables**
Sales made on credit but not systematically tracked.
- *Risk*: Cash flow crisis; bad debt accumulation.
- *Fix*: Debtor management system (see receivables framework below).

---

## Step 3: Redesign — Multi-Account Architecture

### Recommended Bank Account Structure

**For SMEs:**
```
Account 1: TRADING / OPERATING ACCOUNT
  Purpose: All income received here; all operational expenses paid from here
  Access: Finance manager + Director sign-off for >threshold

Account 2: TAX RESERVE ACCOUNT
  Purpose: Hold money set aside for VAT, PAYE, CIT, pension remittances
  Rule: Transfer % of revenue automatically each week/month
  Access: Director only

Account 3: PAYROLL ACCOUNT
  Purpose: Funded once per month from Operating; used only for salary payments
  Rule: Balance = 0 after payroll runs
  Access: HR + Finance dual authorization

Account 4: SAVINGS / EMERGENCY RESERVE
  Purpose: 3–6 months operating expenses held here
  Access: Director only; requires board resolution to access
```

**For Large Companies / Groups:**
Add:
- Project/Contract accounts (ring-fenced per major contract)
- Foreign currency account (USD/GBP/EUR for international transactions)
- Capital expenditure account (funded from budget; separate approval process)
- Subsidiary accounts consolidated at group level

---

## Step 4: Tax Savings Formula

To never be caught short at tax time:

### Nigeria Example
```
Every time revenue hits the bank:
  → Transfer 7.5% to Tax Reserve (VAT collected)
  → Transfer 2% to Tax Reserve (estimated WHT you may owe)
  → Transfer 20–30% to Tax Reserve (CIT provision for profitable companies)

Monthly from payroll:
  → Transfer PAYE + Pension deductions to Tax Reserve immediately
  → Remit by 10th of following month
```

### Universal Rule
Treat tax money as **never yours**. It was collected on behalf of the government. Ring-fence it immediately.

---

## Step 5: Receivables (Money Owed TO You)

### Debtor Aging Framework
```
0–30 days   → Current (acceptable)
31–60 days  → Follow up (send statement + call)
61–90 days  → Escalate (formal demand letter)
91–120 days → Final notice; consider legal action
120+ days   → Provision for bad debt; write-off consideration
```

### Receivables Controls
1. **Credit Limits**: Set maximum credit for each customer before shipping/delivering.
2. **Credit Terms**: Clearly state on invoice (e.g., Net 30, 2/10 Net 30).
3. **Monthly Statements**: Send aged debtor statements to all credit customers.
4. **Collections Policy**: Written policy for escalation steps.
5. **Security**: For large debtors, take post-dated cheques, bank guarantees, or director personal guarantees.

### Bad Debt Provision (Accounting Entry)
```
Dr  Bad Debt Expense          [income statement]
Cr  Allowance for Doubtful Accounts  [contra-asset on balance sheet]

When written off:
Dr  Allowance for Doubtful Accounts
Cr  Accounts Receivable
```

---

## Step 6: Payables (Money Owed BY You)

### 3-Way Match Process
Before any supplier payment is made:
```
1. PURCHASE ORDER (PO)
   → Raised by requesting department
   → Approved by budget holder
   → Sent to supplier

2. GOODS RECEIVED NOTE (GRN)
   → Issued when goods/services received
   → Signed by receiving officer confirming quantity and quality

3. SUPPLIER INVOICE
   → Received from supplier
   → Must match PO and GRN (quantity, price, terms)

Only when all 3 match → Payment approved
```

### Payables Aging (Manage Cash Flow)
- Negotiate supplier terms: Push for Net 45 or Net 60 where possible
- Pay on time (not early, not late) — protect credit rating
- Take early payment discounts (2/10 Net 30) only if it's financially advantageous
  - *Formula*: Annualized discount rate = Discount % ÷ (Days saved ÷ 365)
  - 2% discount for paying 20 days early = 36.5% annualized return — almost always worth it

---

## Step 7: Cash Flow Forecasting

### 13-Week Rolling Cash Flow Forecast (Standard Tool)
Build a weekly forecast 13 weeks out showing:

```
Week 1–13 forecast structure:
  Opening Cash Balance
+ Expected Receipts (invoiced sales due, known income)
- Expected Payments (known supplier invoices, payroll dates, rent, tax)
= Closing Cash Balance

Flag weeks where Closing Balance < Minimum Operating Buffer
```

**Minimum Operating Buffer** = 4–8 weeks of fixed operating expenses.

### Monthly P&L vs Cash Flow — Why They Differ
A company can be profitable but cash-poor. Reasons:
- Revenue recognized but not yet collected (debtors)
- Prepaid expenses (cash out before expense recognized)
- Capital expenditure (cash out; not on P&L, only depreciation)
- Loan repayments (principal repayment not on P&L)
- Inventory buildup (cash spent; asset, not expense)
- VAT collected (cash in but not income — liability)

**Always present both P&L and Cash Flow to business owners.** Profit without cash is dangerous.

---

## Step 8: Internal Controls Checklist

### Segregation of Duties
| Function | Must Be Separate Person From |
|----------|------------------------------|
| Authorizing payments | Processing payments |
| Recording transactions | Reconciling accounts |
| Receiving goods | Authorizing purchases |
| Managing petty cash | Recording petty cash |

### Authorization Matrix (Example)
| Amount | Approval Required |
|--------|------------------|
| Up to ₦50,000 / $50 | Finance Officer |
| ₦50,001–₦500,000 / $50–$500 | Finance Manager |
| ₦500,001–₦5,000,000 / $500–$5,000 | CFO / Director |
| Above ₦5,000,000 / $5,000 | Board Resolution / Two Directors |

### Monthly Controls Checklist
- [ ] Bank reconciliation completed for ALL accounts
- [ ] Petty cash count and reconciliation done
- [ ] Debtor aging reviewed; follow-ups initiated
- [ ] Creditor aging reviewed; upcoming payments planned
- [ ] Payroll reconciled to HR headcount
- [ ] VAT, PAYE, Pension returns prepared (if month-end falls on filing period)
- [ ] Management accounts reviewed by MD/CEO/CFO
- [ ] Budget vs actual variance > 10% investigated and explained
