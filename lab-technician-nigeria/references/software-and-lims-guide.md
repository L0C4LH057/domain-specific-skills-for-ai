# LIMS & Software Guide — Nigerian Lab Technician Context

## Table of Contents
1. Common LIMS Platforms in Nigeria
2. Daily LIMS Workflow Tasks
3. Data Entry Best Practices
4. Offline/Downtime Protocols
5. Result Export & Dispatch
6. HMO & NHIS Billing Integration
7. Common Tech Issues & Fixes
8. Excel/Google Sheets Backup Methods

---

## 1. COMMON LIMS PLATFORMS IN NIGERIA

### AjirMed LIMS
- **Type:** Cloud-based + local server option
- **Best for:** Medium-large hospitals and diagnostic centres
- **Key features:** Offline mode, SMS result dispatch, EMR integration, multi-department worklists, reagent tracking, equipment maintenance logs
- **Nigerian advantage:** Optimised for low-bandwidth and power interruptions; supports NHIS/HMO billing codes
- **Access:** Browser-based; also mobile-accessible
- **Support:** Local Nigerian support team

### ClinikEHR Laboratory
- **Type:** Cloud + offline hybrid
- **Best for:** All sizes of diagnostic centres
- **Key features:** Barcode scanning, auto reference ranges by age/sex, WhatsApp result dispatch, result portal for clinicians
- **Nigerian advantage:** Strong offline capabilities; specifically built for Nigerian regulatory requirements (MLSCN compliance)

### MedLab
- **Type:** Desktop + network
- **Best for:** Established hospital labs, larger centres
- **Key features:** Multi-department, full billing, quality management module
- **Limitation:** Older interface; requires local server; limited mobile access

### LabPro
- **Type:** Desktop (local install)
- **Best for:** Small-medium diagnostic centres
- **Key features:** Basic test registration, result entry, printing
- **Nigerian advantage:** Affordable, locally developed

### Manual/Excel Hybrid (Still common)
- Many Nigerian labs (especially government/primary health) still use:
  - Printed result templates filled by hand
  - Excel spreadsheets for result logging
  - WhatsApp for result images to clinicians
  - Manual registers as primary record

---

## 2. DAILY LIMS WORKFLOW TASKS

### Morning Opening Checklist
```
□ Log in to LIMS (verify correct user account)
□ Check overnight/pending samples from previous shift
□ Print or view worklist for the day
□ Verify QC materials are loaded / reagents are sufficient
□ Run morning QC and document
□ Check instrument status — run daily maintenance
□ Confirm test pending list matches physical samples on bench
```

### Sample Registration / Accessioning
In most LIMS:
1. **New Patient:** Navigate to "New Registration" or "Accession"
2. Enter: Name, Age, Sex, Hospital No., Ward, Doctor
3. Select: Sample Type, Tests Requested, Priority
4. System assigns: Lab Number (or enter manually)
5. Print label (if barcode printer available) and affix to tube
6. Collect payment confirmation / insurance details

### Entering Results
1. Search by Lab Number or Patient Name
2. Open the test order
3. Enter results for each parameter
   - Type in values manually, OR
   - Import from connected analyser (auto-interface)
4. LIMS auto-flags H/L/Critical based on configured reference ranges
5. Add comment if needed (e.g., "haemolysed sample — result may be affected")
6. Save as draft → route for authorisation

### Authorisation
1. Senior MLS logs in with their credentials
2. Reviews pending results queue
3. Checks: patient demographics, result plausibility, QC status
4. Approves/authorises → result becomes "Released"
5. System timestamps authorisation with user name + time

### Searching Past Results (Delta Check)
- Most LIMS: search patient by hospital number → view historical results
- Compare current vs. previous: flag large differences for verification
- Document delta check finding in result comment field

---

## 3. DATA ENTRY BEST PRACTICES

### Golden Rules
- **Always double-check lab number** before entering results — wrong lab number = wrong patient result
- **Use decimal points correctly** — 0.45 not .45; 12.5 not 125 (misplaced decimals are a major error source)
- **Enter units as per system configuration** — don't mix mmol/L and mg/dL for glucose
- **Never leave mandatory fields blank** — especially date/time and reporter name
- **Don't share login credentials** — each staff member must use their own account for audit trail
- **Manual entry flag** — when entering results manually (not auto-imported), flag as "Manual entry" in LIMS

### Reference Range Configuration
Some smaller labs may need to manually set up reference ranges in LIMS:
- Enter age-specific and sex-specific ranges
- Set critical value thresholds
- Test the flags by entering a borderline value before go-live

### Batch Entry (High Volume Days)
- Use the LIMS worklist / batch entry screen
- Scan barcodes sequentially to load next sample
- Review batch before bulk authorisation
- Do NOT bulk-authorise without checking each result

---

## 4. OFFLINE / DOWNTIME PROTOCOLS

### When LIMS Goes Offline (Power cut / Internet loss / Server down)
**Immediate steps:**
1. Note the time in the manual logbook
2. Switch to **paper request/result forms**
3. Continue registering patients manually (use sequential manual lab numbers, e.g., prefix "M" for manual: M001, M002...)
4. Record all results in departmental logbook
5. Continue analysis normally — instruments don't need LIMS to run tests

**When system restores:**
1. Enter all manual records retroactively into LIMS
2. Use original collection/reporting times (not the time of LIMS entry)
3. Note: "Entered retroactively — LIMS downtime" in the comment field
4. Verify each manual result matches what was written on paper form

**Generator/Inverter strategy:**
- Priority equipment on generator/inverter: analysers, centrifuge, refrigerator/freezer
- Laptop/desktop LIMS: keep charged; use laptop for as long as battery lasts offline
- UPS (Uninterruptible Power Supply): essential for server protection — prevents data corruption during power cut

---

## 5. RESULT EXPORT & DISPATCH

### Printing Results
- Use LIMS print function for official result reports
- Always preview before printing — check all fields are populated
- Print on lab letterhead paper (or ensure LIMS template includes header/footer)
- Sign printed result (authorising MLS signature)

### SMS Dispatch (e.g., AjirMed, ClinikEHR)
- System sends automated SMS to patient's registered phone: "Your result is ready. Please collect or log in to [portal]."
- Some systems send result summary via SMS (check privacy policy with your lab manager)
- Bulk SMS dispatch: only use verified phone numbers from registration

### Email to Clinicians
- Use official lab email address (not personal Gmail)
- Attach result as PDF (password-protect if containing sensitive data)
- Subject line format: *"Lab Result — [Patient Hospital No.] — [Date]"*

### WhatsApp (Informal Practice — Common in Nigeria)
- Widely used in smaller labs — photograph of printed result sent to doctor's phone
- **Risk:** Not secure; no audit trail; patient privacy concern
- Best practice: If used, send only to verified clinician; document that result was dispatched
- Consider transitioning to official SMS/portal for compliance

### Online Portal Access
- Larger LIMS systems (AjirMed, ClinikEHR) offer patient/clinician portals
- Clinicians can log in and view results in real-time
- Set up requires: clinician registration, secure login credentials, appropriate access permissions

---

## 6. HMO & NHIS BILLING INTEGRATION

Many Nigerian labs work with Health Maintenance Organisations (HMOs) and the National Health Insurance Scheme (NHIS). The LIMS must handle:

### HMO Workflow
1. Patient presents HMO card → verify eligibility (call HMO or use online portal)
2. Register patient under their HMO in LIMS
3. Select tests covered under their HMO plan
4. Generate authorisation code (some HMOs require pre-authorisation per test)
5. Process tests and generate result
6. Generate HMO invoice/claim in LIMS
7. Submit claim (monthly/weekly) to HMO for reimbursement

### Common HMOs in Nigeria
- Hygeia, Leadway Health, AXA Mansard, Reliance HMO, AIICO Multishield, Total Health Trust (THT), Avon HMO

### NHIS
- Government scheme — common in federal/state hospitals
- Very low tariff rates; often underfunded
- Register patient, select NHIS-approved tests, generate claim

### HMO Rejections (Common Issues)
| Issue | Fix |
|---|---|
| Test not in HMO panel | Inform patient; they pay out of pocket |
| Authorisation code expired | Re-call HMO for new code |
| Patient plan suspended | Patient pays cash; advise them to contact HMO |
| Claim rejected — wrong code | Check ICD-10 or NHIS tariff code; resubmit |

---

## 7. COMMON TECH ISSUES & FIXES

### LIMS Slow/Unresponsive
- Cause: Many open browser tabs, low RAM, server congestion
- Fix: Close other tabs/apps, refresh page, clear browser cache, use Chrome/Edge (not old IE)
- If persists: restart browser, call IT/support

### Barcode Scanner Not Reading
- Clean scanner window with dry cloth
- Check USB connection
- Test scanner on a known good barcode
- If tube label is wrinkled/smudged: enter lab number manually

### Analyser Not Connecting to LIMS (Interface Error)
- Check network cable connection (analyser to LAN)
- Restart the interface middleware (if applicable)
- Enter result manually and flag "Manual entry — interface fault"
- Log the incident and notify IT

### Result Printout Cutting Off
- Check paper alignment in printer
- Verify print template margins in LIMS settings
- Print to PDF first to confirm format is correct

### Date/Time Error on Results
- LIMS server time must match actual time — check server clock settings
- If server time is wrong: notify IT immediately; don't release results until fixed (audit trail depends on accurate timestamps)

### Forgot Password / Account Locked
- Use LIMS "Forgot Password" function or call IT/admin
- Never use another staff member's account as a workaround
- Document reason for delay in logbook

---

## 8. EXCEL / GOOGLE SHEETS BACKUP METHODS

For labs using Excel/Sheets as primary or backup system:

### Recommended Excel Template Structure

**Sheet 1: Patient Register**
| Lab No | Date | Patient Name | Age | Sex | Hospital No | Ward | Doctor | Tests | Sample |

**Sheet 2: Results Log**
| Lab No | Test | Result | Unit | Ref Range | Flag | Reported By | Date Reported |

**Sheet 3: QC Log**
| Date | Instrument | Control Level | Expected Range | Observed Value | Pass/Fail | Action Taken | Initials |

**Sheet 4: Rejection Log**
| Date | Lab No | Patient Name | Rejection Reason | Action Taken | Notified By |

### Google Sheets Advantages in Nigerian Context
- Auto-saves to cloud (protects against local power loss/hardware failure)
- Multi-user access (multiple staff can enter simultaneously)
- Access from phone when desktop is unavailable
- Works offline (Google Sheets offline mode on Chrome)

### Excel Data Protection
- Password-protect the workbook (File → Info → Protect Workbook)
- Lock result columns after entry to prevent accidental changes
- Back up to external USB at end of each shift
- Keep at least 3 backup copies: local PC, USB, and cloud (Google Drive or email to yourself)
