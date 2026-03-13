# Accounting Software Guide by Size & Country

## Decision Framework

Before recommending software, answer:
1. What is the company's annual revenue / size?
2. How many users need access?
3. Is internet connectivity reliable?
4. Does the company operate in multiple currencies?
5. Does it need payroll, inventory, or project management built in?
6. What is the monthly budget for software?

---

## By Company Size

### Micro / Sole Trader (Revenue < $100,000 / ₦50m)

**Wave** (Free)
- Best for: Freelancers, sole traders, very small businesses
- Countries: Works globally; USD/GBP/NGN supported
- Features: Invoicing, expense tracking, basic P&L, receipt scanning
- Payroll: USA and Canada only (paid add-on)
- Limitation: No inventory, limited multi-currency, no local VAT automation

**Zoho Books** (Free tier / ~$15/mo)
- Best for: Small service businesses
- Countries: Nigeria, Kenya, South Africa, Ghana, UK, US, UAE (localized VAT)
- Features: Invoicing, bank feeds, VAT returns, multi-currency
- Payroll: Via Zoho Payroll (separate product)

**QuickBooks Simple Start** (~$30/mo)
- Best for: Simple service businesses in US/UK
- Countries: US, UK, CA, AU (localized versions)

---

### Small Business (Revenue $100K–$1M / ₦50m–₦500m)

**QuickBooks Online (QBO) — Essentials / Plus**
- Best for: Service and retail businesses; best ecosystem of accountants globally
- Countries: Nigeria, Ghana, Kenya, South Africa, UK, US, Canada — all localized
- Features: Bank feeds, multi-user, VAT/GST returns, inventory (Plus), project tracking
- Payroll: Built-in (US, UK, CA); third-party integration for others
- Nigeria: Supports naira multi-currency; popular with Lagos SMEs
- Cost: ~$60–$90/month

**Xero**
- Best for: Cloud-native businesses; excellent bank feed integration
- Countries: UK, Australia, NZ, South Africa; limited in West Africa
- Features: MTD-VAT (UK), excellent reporting, strong accountant ecosystem
- Cost: ~$50–$70/month

**Sage Business Cloud Accounting**
- Best for: Manufacturing, distribution in Africa; strong SARS/HMRC compliance
- Countries: South Africa (excellent), UK, Nigeria, Ghana, Kenya
- Features: Invoicing, inventory, payroll (Sage Payroll), VAT returns
- Cost: Varies by region (~₦15,000–₦50,000/month in Nigeria)

---

### Medium Business (Revenue $1M–$10M / ₦500m–₦5bn)

**QuickBooks Online Advanced**
- Features: Up to 25 users, custom reporting, workflow automation, dedicated support
- Cost: ~$200/month

**Sage 50cloud / Sage 200**
- Best for: Manufacturing, retail with inventory complexity
- Countries: UK, South Africa primarily; some African coverage
- Features: Full stock management, job costing, CIS (UK construction)

**Odoo (Community or Enterprise)**
- Best for: Companies wanting integrated ERP (accounting + inventory + CRM + HR)
- Countries: Global; highly customizable for local requirements
- Features: Fully modular; Nigerian FIRS reports available via community modules
- Cost: Community (free, self-hosted); Enterprise (~$25/user/month + implementation)

**Tally Prime**
- Best for: Manufacturing, trading companies; dominant in Nigerian manufacturing sector
- Countries: Nigeria, Ghana, India, East Africa; strong local consultant network
- Features: Excellent inventory, statutory compliance, multi-branch
- Cost: ₦150,000–₦300,000/year (license)

---

### Large Business / Group ($10M+ / ₦5bn+)

**SAP Business One**
- Best for: Large SMEs needing full ERP with local compliance
- Countries: Nigeria, Kenya, South Africa, UK, US, UAE — localized versions
- Features: Full financial, HR, supply chain, multi-company consolidation
- Cost: $2,000–$4,000+ per user (one-time) + annual maintenance

**Microsoft Dynamics 365 Business Central**
- Best for: Microsoft-ecosystem companies; mid-large market
- Countries: Global; good African partner network
- Cost: ~$70–$100/user/month

**Oracle NetSuite**
- Best for: Multi-entity, multi-currency, complex group structures
- Countries: Global; strong compliance engine
- Cost: $999+/month base + per user

**ERPNext** (Open Source)
- Best for: Cost-conscious mid-large companies; tech-savvy teams
- Countries: Global; Nigerian payroll and VAT modules available
- Features: Full ERP; requires implementation partner
- Cost: Free (self-hosted) to $50+/user/month (cloud)

---

## Mobile Money & Payment Integration (Africa-Specific)

For Nigerian/African businesses, ensure software integrates with:

| Platform | Countries | Use Case |
|----------|-----------|----------|
| **Flutterwave** | NG, GH, KE, ZA, RW + more | Multicurrency payments, collections |
| **Paystack** | NG, GH, ZA, KE | Local payments, invoicing |
| **M-Pesa** | KE, TZ, GH, EG | Mobile money collections |
| **Interswitch** | NG | POS, card payments |
| **OPay / Moniepoint** | NG | Agent banking, POS |

Most QBO/Xero/Odoo installations in Nigeria use **bank feeds** rather than direct payment integrations — configure bank to send CSV export or connect via third-party connector.

---

## Implementation Tips

### Migrating from Manual Books / Excel to Software

1. **Choose a clean start date** (beginning of new financial year is ideal; mid-year is possible)
2. **Enter opening balances**: All assets, liabilities, equity at that date
3. **Don't try to back-enter years of data** — use adjusting journal entries for opening balances
4. **Run parallel for 1–2 months** (manual + software simultaneously to verify)
5. **Train all users** before go-live; assign roles and permissions
6. **Lock prior periods** after reconciliation to prevent accidental changes

### Key Software Settings to Configure on Day 1
- Company name, registration number, tax ID (TIN, VAT number)
- Financial year start date
- Base currency
- Tax rates (VAT rate, withholding tax rates)
- Chart of accounts (customize to company)
- Bank accounts (connect feeds if available)
- Invoice template (logo, payment terms, bank details)
- User roles and permissions
- Default payment terms (for customers and suppliers)
