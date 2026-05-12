# Result Recording & Reporting — Nigerian Lab Standards

## Table of Contents
1. LIMS Workflow (Digital Entry)
2. Manual Logbook Recording
3. Standard Lab Result Report Templates
4. Result Authorisation & Release
5. Critical Value Notification
6. Result Dispatch (SMS, Print, Portal)
7. Common LIMS Error Codes & Fixes

---

## 1. LIMS WORKFLOW (DIGITAL ENTRY)

### Standard Workflow in Nigerian Labs

```
REQUEST RECEIVED
      ↓
ACCESSIONING (Register patient + assign Lab Number)
      ↓
SPECIMEN RECEIPT & ACCEPTANCE/REJECTION CHECK
      ↓
TEST ASSIGNMENT (link test(s) to lab number)
      ↓
SAMPLE PROCESSING (centrifuge, separate, etc.)
      ↓
ANALYSIS (manual or instrument)
      ↓
RESULT ENTRY INTO LIMS
      ↓
INTERNAL QUALITY CHECK / QC VERIFICATION
      ↓
AUTHORISATION BY SENIOR SCIENTIST/PATHOLOGIST
      ↓
RESULT RELEASE / DISPATCH
      ↓
RESULT PRINTING / SMS / PORTAL UPLOAD
```

### Accessioning Fields (Mandatory in LIMS)
Every patient record must capture:
- **Patient Name** (Last, First Middle)
- **Age** and **Date of Birth** (if available)
- **Sex** (Male/Female)
- **Hospital/Clinic Number** (unique identifier)
- **Ward / Clinic / Outpatient unit**
- **Requesting Physician / Consultant**
- **Date and Time of Sample Collection**
- **Sample Type** (blood, urine, swab, stool, etc.)
- **Tests Requested** (each test itemised)
- **Clinical Information** (diagnosis/reason for test — important for result interpretation)
- **Priority:** Routine / Urgent / STAT / Emergency
- **Payment Status** (in most Nigerian labs: Paid / HMO / NHIS / Waived)

### Lab Number Format
Most Nigerian labs use a format like:
- `LAB-YYYYMMDD-XXXXX` (e.g., LAB-20240415-00127)
- Or sequential daily: `250415-001`, `250415-002`...
- Some HMO labs use the payer's reference number as prefix

---

## 2. MANUAL LOGBOOK RECORDING

Even in digital labs, a **manual backup register** is mandatory per best practice (and often required for MLSCN inspection). This is critical during power outages and LIMS downtime.

### Standard Logbook Columns
| Column | Content |
|---|---|
| Date | DD/MM/YYYY |
| Serial No. | Daily sequential number |
| Lab No. | Assigned LIMS or manual reference |
| Patient Name | Last name, First name |
| Age / Sex | e.g., 32/M |
| Hospital No. | Patient unique ID |
| Ward/Clinic | Location |
| Test(s) Requested | FBC, LFT, MP, etc. |
| Sample Type | Blood (EDTA), Serum, Urine, etc. |
| Sample Condition | Satisfactory / Haemolysed / Clotted / Insufficient |
| Result(s) | Entered after analysis |
| Reference Range | Printed or written next to result |
| Flag | H / L / * (Critical) |
| Reported By | Initials + MLSCN Reg. No. |
| Date/Time Reported | When result was authorised |
| Remarks | QC issues, repeat, sample rejected |

### Departmental Logbooks Required
- **Haematology Register**
- **Chemical Pathology (Biochemistry) Register**
- **Microbiology Register**
- **Serology / Immunology Register**
- **Urinalysis Register**
- **Specimen Rejection Log**
- **QC Log / Levey-Jennings Chart folder**
- **Equipment Maintenance Log**
- **Reagent Receipt & Usage Log**

---

## 3. STANDARD LAB RESULT REPORT TEMPLATES

### A. HAEMATOLOGY REPORT (FBC)

```
══════════════════════════════════════════════
        [HOSPITAL/LAB NAME]
        [Address] | Tel: [Phone] | Email: [Email]
══════════════════════════════════════════════
         HAEMATOLOGY RESULT REPORT
──────────────────────────────────────────────
Patient Name:          ______________________
Age / Sex:             _______ / ___________
Hospital No.:          ______________________
Ward / Clinic:         ______________________
Requesting Doctor:     ______________________
Sample Type:           EDTA Whole Blood
Date Collected:        ______________________
Date Reported:         ______________________
Lab Number:            ______________________
──────────────────────────────────────────────
FULL BLOOD COUNT (FBC)
──────────────────────────────────────────────
TEST                   RESULT   UNIT   REF RANGE         FLAG
Haemoglobin (Hb)       ______   g/dL   M:13.0-17.0      ____
                                        F:12.0-16.0
PCV / Haematocrit      ______   L/L    M:0.40-0.50       ____
RBC Count              ______   ×10¹²  M:4.5-5.5         ____
MCV                    ______   fL     80-100             ____
MCH                    ______   pg     27-33              ____
MCHC                   ______   g/dL   31.5-35.0         ____
WBC (Total)            ______   ×10⁹   4.0-11.0          ____
Neutrophils            ______   %      40-75              ____
Lymphocytes            ______   %      20-40              ____
Monocytes              ______   %      2-10               ____
Eosinophils            ______   %      1-6                ____
Basophils              ______   %      0-1                ____
Platelets              ______   ×10⁹   150-400           ____
ESR (Westergren)       ______   mm/hr  M:<15; F:<20      ____
──────────────────────────────────────────────
Blood Film Comment:
___________________________________________________

COMMENT:
___________________________________________________

H = High  |  L = Low  |  * = CRITICAL VALUE

Reported By: _______________ (MLSCN Reg. No.: ________)
Authorised By: _____________ Signature: _______________
Date/Time: _____________________________________________
══════════════════════════════════════════════
```

---

### B. CHEMICAL PATHOLOGY REPORT (LFT + RFT)

```
══════════════════════════════════════════════
        [HOSPITAL/LAB NAME]
        [Address] | Tel: [Phone]
══════════════════════════════════════════════
     CHEMICAL PATHOLOGY RESULT REPORT
──────────────────────────────────────────────
Patient Name:     ___________________________
Age / Sex:        __________ / ______________
Hospital No.:     ___________________________
Ward / Clinic:    ___________________________
Requesting Doctor:___________________________
Sample Type:      Serum (plain)
Date Collected:   ___________________________
Date Reported:    ___________________________
Lab Number:       ___________________________
──────────────────────────────────────────────
LIVER FUNCTION TESTS (LFT)
──────────────────────────────────────────────
TEST                RESULT   UNIT     REFERENCE     FLAG
Total Bilirubin     ______   µmol/L   3.0-21.0      ____
Direct Bilirubin    ______   µmol/L   0-5.0         ____
ALT (SGPT)          ______   U/L      7-56          ____
AST (SGOT)          ______   U/L      10-40         ____
ALP                 ______   U/L      44-147        ____
GGT                 ______   U/L      M:8-61        ____
                                       F:5-36
Total Protein       ______   g/L      64-83         ____
Albumin             ______   g/L      35-52         ____
Globulin            ______   g/L      20-35         ____
──────────────────────────────────────────────
RENAL FUNCTION TESTS (E/U/Cr)
──────────────────────────────────────────────
TEST                RESULT   UNIT     REFERENCE     FLAG
Urea                ______   mmol/L   2.5-7.5       ____
Creatinine          ______   µmol/L   M:62-115      ____
                                       F:53-97
Sodium (Na⁺)        ______   mmol/L   135-145       ____
Potassium (K⁺)      ______   mmol/L   3.5-5.0       ____
Chloride (Cl⁻)      ______   mmol/L   95-107        ____
Bicarbonate (HCO₃⁻) ______  mmol/L   22-29         ____
──────────────────────────────────────────────
COMMENT:
___________________________________________________

H = High  |  L = Low  |  * = CRITICAL VALUE

Reported By: _______________ (MLSCN Reg. No.: ________)
Authorised By: _____________ Date: ____________________
══════════════════════════════════════════════
```

---

### C. MICROBIOLOGY / SEROLOGY REPORT

```
══════════════════════════════════════════════
        [HOSPITAL/LAB NAME]
══════════════════════════════════════════════
    MICROBIOLOGY / SEROLOGY RESULT REPORT
──────────────────────────────────────────────
Patient Name:       _________________________
Age / Sex:          _________ / ____________
Hospital No.:       _________________________
Ward / Clinic:      _________________________
Requesting Doctor:  _________________________
Sample Type & Site: _________________________
Date Collected:     _________________________
Date Reported:      _________________________
Lab Number:         _________________________
──────────────────────────────────────────────
[SECTION HEADING — e.g., MALARIA PARASITE]

Result:
___________________________________________________
___________________________________________________

[SECTION HEADING — e.g., WIDAL REACTION]

Result:
___________________________________________________

[SECTION HEADING — e.g., HIV SCREENING]

Result: REACTIVE / NON-REACTIVE
Method: ___________________________________________

[SECTION HEADING — e.g., HBsAg]

Result: REACTIVE / NON-REACTIVE
──────────────────────────────────────────────
COMMENT:
___________________________________________________

Reported By: _______________ (MLSCN Reg. No.: ________)
Authorised By: _____________ Date: ____________________
══════════════════════════════════════════════
```

---

### D. URINALYSIS REPORT

```
══════════════════════════════════════════════
    URINALYSIS RESULT REPORT
──────────────────────────────────────────────
Lab No.: ______ Patient: ___________________
Age/Sex: ___/___  Date: ___________________
──────────────────────────────────────────────
MACROSCOPY
Colour:         _______________
Appearance:     _______________

DIPSTICK RESULTS
Parameter       Result          Normal
pH              ___             4.5–8.0
Specific Gravity___             1.003–1.030
Protein         ___             Negative
Glucose         ___             Negative
Blood           ___             Negative
Leucocytes      ___             Negative
Nitrites        ___             Negative
Ketones         ___             Negative
Bilirubin       ___             Negative
Urobilinogen    ___             Normal

MICROSCOPY (per HPF)
Pus cells (WBCs):  ___ /HPF    (Normal: 0–5)
RBCs:              ___ /HPF    (Normal: 0–3)
Epithelial cells:  ___
Casts:             ___
Crystals:          ___
Organisms:         ___
Other:             ___
──────────────────────────────────────────────
COMMENT:
___________________________________________________

Reported By: _______________ (MLSCN Reg. No.: ________)
══════════════════════════════════════════════
```

---

## 4. RESULT AUTHORISATION & RELEASE

### Authorisation Levels
| Level | Who | What They Authorise |
|---|---|---|
| Level 1 | Lab Technician (MLT) | Routine normal results |
| Level 2 | Medical Lab Scientist (MLS) | All results, abnormal values |
| Level 3 | Senior MLS / Lab Manager | Critical values, discordant results |
| Level 4 | Consultant Chemical Pathologist / Haematologist | Complex cases, TATL results, medico-legal |

**In Nigerian labs, most routine results are authorised by the on-duty MLS.**
Critical values MUST involve a senior or consultant before release.

### Before Releasing ANY Result, Verify:
- [ ] Patient demographics match request form
- [ ] Lab number on result matches specimen tube label
- [ ] All requested tests are reported
- [ ] QC for that run was acceptable
- [ ] Critical values have been verbally communicated to the ward
- [ ] Authorised by appropriate staff level
- [ ] Date and time of reporting recorded

---

## 5. CRITICAL VALUE NOTIFICATION

**When a critical value is generated:**
1. **Do not release result silently** — call the ward/clinic immediately
2. Document in the **Critical Value Log**:
   - Date & time of test
   - Patient name & lab number
   - Test & result
   - Person who received the call (name + designation)
   - Time of call
   - Lab staff member who called
3. In LIMS, flag the result as **"Critical — Verbal Report Given"**
4. Release the printed/digital report after verbal communication

### Critical Value Thresholds (Nigerian Standard)
| Test | Low Critical | High Critical |
|---|---|---|
| Haemoglobin | < 5.0 g/dL | > 20.0 g/dL |
| WBC | < 2.0 × 10⁹/L | > 30 × 10⁹/L |
| Platelets | < 50 × 10⁹/L | > 1000 × 10⁹/L |
| Blood Glucose | < 2.5 mmol/L | > 25 mmol/L |
| K⁺ | < 2.5 mmol/L | > 6.5 mmol/L |
| Na⁺ | < 120 mmol/L | > 155 mmol/L |
| Creatinine | — | > 700 µmol/L |
| INR | — | > 5.0 |
| CSF: positive organism | — | Any |

---

## 6. RESULT DISPATCH METHODS

### In Nigerian Labs (Common Methods):
1. **Print and collect at lab counter** — most common, patient/relative picks up
2. **SMS notification** — "Your result is ready. Please collect at Lab Reception." (AjirMed supports this)
3. **Email to requesting physician** — used in larger/private hospitals
4. **Doctor's portal/EMR view** — in hospitals with integrated EMR + LIMS
5. **Telephone result** — for urgent/STAT results; always followed by written report
6. **WhatsApp (informal)** — common in smaller diagnostic centres; not officially recommended but widely used for result images

**Privacy Note:** When sending via SMS/WhatsApp, result content should be minimal or coded. Full result dispatch should be to verified clinician contact only.

---

## 7. COMMON LIMS ERROR CODES & TROUBLESHOOTING

| Issue | Cause | Fix |
|---|---|---|
| "Sample not found" | Lab number entered wrong | Re-check physical label and request form |
| "Test not linked to sample" | Sample registered but test not added | Go to sample → add test request |
| "QC failed" | QC control out of range | Repeat QC; if fails again, change reagent lot and re-run |
| Result won't authorise | Not all tests complete | Check for pending tests on the same order |
| Duplicate lab number | Data entry error | Merge or delete duplicate; check with reception |
| Analyser result not importing | Interface/HL7 error | Re-send from analyser or manually enter and flag "manual entry" |
| System slow/frozen | Server overload or low storage | Notify IT; use manual logbook backup |
| LIMS offline | Power/internet loss | Switch to paper backup; enter retroactively when system restores |

**Best practice:** Always export a daily backup of results to USB/external drive, especially before closing the lab shift. This protects against data loss during NEPA outages.
