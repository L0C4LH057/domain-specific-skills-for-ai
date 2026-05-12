# Sample Handling SOPs — MLSCN-Aligned Nigerian Lab Guidelines

## Table of Contents
1. Pre-Analytical Phase (Before Testing)
2. Analytical Phase (During Testing)
3. Post-Analytical Phase (After Testing)
4. Specimen Rejection Criteria
5. Biosafety & Infection Control
6. Sample Storage & Retention
7. Chain of Custody & Traceability

---

## 1. PRE-ANALYTICAL PHASE

The pre-analytical phase is where **most laboratory errors occur** (estimated 60–70% of all errors). Strict adherence prevents repeat collections and wrong results.

### Patient Identification (ALWAYS verify before collection)
- Ask patient to state full name + one other identifier (date of birth or hospital number)
- **Never assume** based on bed/ward alone
- In LIMS: scan patient barcode or verify manually

### Sample Collection Best Practices

**Blood Collection:**
1. Explain procedure to patient (get verbal consent)
2. Select appropriate vein (antecubital preferred)
3. Apply tourniquet — **release within 60 seconds** of application (prolonged tourniquet causes haemoconcentration — affects K⁺, proteins, cell counts)
4. Clean with 70% alcohol swab — allow to dry before venepuncture
5. Collect in correct order of draw (see tests reference file)
6. Fill tubes to **manufacturer's marked line** — especially blue (citrate) tubes
7. Mix gently by 5–8 gentle inversions (do NOT shake — causes haemolysis)
8. Label **immediately at the bedside** — before leaving the patient
9. Transport to lab within recommended time

**Capillary Blood (Finger Prick):**
- Use for: blood glucose, malaria RDT, neonatal samples
- Clean fingertip with alcohol — dry before puncture
- Discard first drop
- Avoid squeezing excessively (dilutes with tissue fluid)

**Urine Collection:**
- Midstream clean-catch for M/C/S (most important)
- First morning urine preferred for urinalysis
- Instruct patient: clean genital area, begin urinating, discard first stream, collect midstream into sterile container
- Deliver to lab within **2 hours** or refrigerate at 2–8°C

**HVS / Cervical Swabs:**
- Trained clinical staff only (nurse/doctor)
- Use sterile swab; place in transport medium (Amies/Stuarts)
- Label with patient name, site of collection, date/time
- Deliver within 2 hours; if delayed, refrigerate (not for gonorrhoea — transport immediately at body temp if possible)

**Stool Samples:**
- Collect in clean, dry, leak-proof container
- Size: at least 1 teaspoon (5–10 mL/grams)
- Do NOT contaminate with urine
- Label and deliver to lab within 1 hour for M/C/S

**Sputum (AFB):**
- Early morning, deep cough (not saliva)
- Volume: ≥ 3–5 mL of true sputum
- 3 consecutive early morning specimens (preferably)
- Label with date/time; deliver promptly

### Transport Conditions
| Sample Type | Temperature | Max Time to Lab |
|---|---|---|
| EDTA blood (FBC) | Room temp | 4–6 hours |
| Citrate blood (coag.) | Room temp | 4 hours (centrifuge within 1 hr ideally) |
| Serum/Plain | Room temp → refrigerate if >2 hrs | 8 hours at RT; 48 hrs refrigerated |
| Fluoride blood (glucose) | Room temp | 24 hours (fluoride preserves glucose) |
| Urine | Room temp | 2 hours; refrigerate if longer |
| CSF | Room temp immediately | 15–30 minutes MAX to lab |
| Swabs in transport medium | Room temp | 24–48 hours (varies by organism) |
| Stool | Room temp | 1 hour; refrigerate up to 24 hrs |

---

## 2. ANALYTICAL PHASE

### Quality Control (QC) — MUST be done before patient results
- Run **control materials** (normal and abnormal levels) at start of every shift / batch
- Document in QC log with date, lot number, expected range, observed result, pass/fail
- Use **Levey-Jennings charts** to track QC performance over time
- **Westgard Rules** for automated analysers:
  - 1₂s: Warning (result is 2 SD from mean)
  - 1₃s: Reject run (result is 3 SD from mean)
  - R₄s: Reject (range between two controls exceeds 4 SD)
  - 2₂s: Reject (two consecutive controls exceed 2 SD same direction)

**If QC fails:** Do NOT release patient results. Troubleshoot: check reagent expiry, re-calibrate instrument, use fresh controls, call technical support.

### Instrument Checks (Daily)
- [ ] Power on and warm-up (per manufacturer specs)
- [ ] Check reagent levels — no empty reagents
- [ ] Run maintenance (e.g., auto-wash on haematology analyser)
- [ ] Check consumables (cuvettes, printer paper/labels)
- [ ] Document in equipment maintenance log
- [ ] Run QC after maintenance
- [ ] Check expiry dates of all reagents in use

### Common Nigerian Lab Instruments
| Equipment | Department | Examples Used |
|---|---|---|
| Haematology analyser | Haematology | Sysmex, Mindray BC series |
| Biochemistry analyser | Chemical Path. | Mindray BS series, BioSystems, Humalyzer |
| Centrifuge | All | Micro/macro centrifuge (3000–5000 rpm) |
| Microscope | Micro/Haem/Urine | Binocular; oil immersion (×100) for blood films |
| HIV rapid test reader | Serology | Manual visual interpretation |
| Glucose meter (POCT) | Emergency/Wards | Accu-Check, OneTouch |
| Urine analyser (dipstick reader) | Urinalysis | Cobas u411, Mindray UA-120 |
| Water bath / incubator | Microbiology | 35–37°C for cultures |
| Autoclave | Microbiology | For sterilisation |

---

## 3. POST-ANALYTICAL PHASE

### After Analysis:
1. Review result for clinical plausibility (delta check — compare with previous result if available)
2. Enter result in LIMS and/or logbook
3. Authorise result (appropriate staff level — see reporting guide)
4. Flag abnormal/critical values
5. Notify ward for critical values (document the call)
6. Dispatch result (print, SMS, portal)
7. File/retain paperwork

### Delta Check
Compare current result with previous result for same patient:
- Haemoglobin: flag if change > 2 g/dL without explanation
- K⁺: flag if change > 1.0 mmol/L
- Creatinine: flag if change > 50% without explanation
- If delta check fails: verify specimen identity, repeat test, contact ward

---

## 4. SPECIMEN REJECTION CRITERIA

A specimen should be **rejected and a new sample requested** if:

| Rejection Reason | Description | Action |
|---|---|---|
| Unlabelled | No patient name/ID on tube | Reject — request new sample |
| Mislabelled | Name on tube does not match request form | Reject — verify and recollect |
| Haemolysed | Pink/red serum due to RBC lysis | Affects K⁺, LDH, many biochemistry tests — recollect |
| Clotted | Clot in EDTA tube (should not clot) | Reject — recollect |
| Insufficient volume | Below minimum required | Partial reporting only or reject |
| Wrong tube type | e.g., EDTA used for serology | Recollect in correct tube |
| Lipemic | Very cloudy/milky serum | Note on report; may affect spectrophotometric tests |
| Icteric | Very yellow serum | Note on report; may affect some assays |
| Delayed transport | Specimen >8 hours at RT (serum) | Evaluate on case-by-case basis; glucose invalid in plain tube |
| Broken/leaking tube | Biohazard risk + sample loss | Reject; clean up safely |

**All rejections must be documented in the Specimen Rejection Log** with:
- Date, lab number, patient name, reason for rejection, notified by whom, action taken

---

## 5. BIOSAFETY & INFECTION CONTROL

### Personal Protective Equipment (PPE) — Always in the Lab
- Lab coat (always)
- Nitrile/latex gloves (change between patients)
- Eye protection (if aerosol risk)
- Mask (when processing respiratory specimens, TB samples)

### Standard Precautions (Nigeria NCDC Guidelines)
- **All patient specimens are potentially infectious** — treat accordingly
- Never pipette by mouth
- Do not eat, drink, or apply cosmetics in the lab
- Wash hands before and after each procedure
- Dispose of sharps in puncture-resistant containers (never recap needles by hand)
- Dispose of infectious waste in biohazard bags (yellow in most Nigerian labs)
- Liquid waste: decontaminate with 1% sodium hypochlorite (bleach) before disposal

### Biosafety Cabinet
- Required for: TB samples (Biosafety Level 2+), culture of unknown organisms, HIV viral load
- Wipe down with 70% ethanol before and after use

### Needle-Stick Injury Protocol (Nigerian Ministry of Health)
1. Immediately squeeze wound to encourage bleeding
2. Wash thoroughly with soap and running water (5 minutes)
3. Report to supervisor and occupational health officer IMMEDIATELY
4. Fill incident form
5. Source patient tested for HIV, HBV, HCV (with consent)
6. Commence PEP (Post-Exposure Prophylaxis) for HIV within **72 hours** (ideally <2 hours) if source is HIV+/unknown

---

## 6. SAMPLE STORAGE & RETENTION

Per MLSCN Sample Management Guidelines:

| Sample/Slide Type | Retention Period |
|---|---|
| Serum/plasma (frozen) | 7 days routine; longer for complex cases |
| EDTA blood (refrigerated) | 24–48 hours |
| Urine | 24 hours (2–8°C) |
| Standard stained blood slides | 18 months |
| Fluorescence-stained slides | 3 months |
| AFB (ZN stained) slides | 1 year |
| Culture media/positive cultures | Until case is resolved |
| Request forms | 5 years minimum |
| Lab registers/logbooks | 7 years minimum |

**Storage conditions:**
- -20°C freezer: long-term serum/plasma storage
- 2–8°C fridge: short-term blood, urine, swabs in transport media
- Room temp: slides, fixed stained preparations
- Dark storage: fluorescence/immunofluorescence slides

---

## 7. CHAIN OF CUSTODY & TRACEABILITY

Every sample must have a documented, unbroken chain from:
**Patient → Collection → Transport → Receipt → Analysis → Result → Storage/Disposal**

Key traceability elements:
- Who collected the sample (name/initials on form)
- Date and time of collection
- Date and time of receipt in lab
- Condition on arrival (acceptable/rejected — documented)
- Who performed the analysis
- Who authorised the result
- Date and time of result release

**Medico-legal specimens** (e.g., rape kit, forensic toxicology, drug screen for legal purposes) require **strict chain of custody documentation**, tamper-evident sealing, and may require witness signatures at each transfer point. Always escalate these to the Lab Manager.
