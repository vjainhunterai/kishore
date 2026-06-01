-- =============================================================================
-- HARDCODED SIMILARITY MATCH INSERT — EXTENSION PIPELINE STEP E6b
-- =============================================================================
-- PURPOSE  : Insert AP rows that were NOT matched by Tier 1 (prefix/exact)
--            using manually reviewed similarity matches.
--            These are keyed by seq_no (exact AP row identifier).
--
-- MATCH FLAG : 'MNP_Similarity_Match'
--
-- CONFIDENCE TIERS (documented per row):
--   HIGH   → Token Set Ratio ≥ 80  — approved for insert
--   MEDIUM → Token Set Ratio 65-79 — reviewed & approved
--   MANUAL → Score < 65            — manually verified before insert
--
-- NOTE: T.R.A.C. Y-CONNECTOR (seq_no 900326, 958364) excluded —
--       score too low (51), no reliable MNP candidate found.
--       Add correct MNP description to master before including.
-- =============================================================================


-- ── PP-CA-449 ─────────────────────────────────────────────────────────────

-- PACEMAKER CARDIAC DUAL CHAMBER RF TELEMETRY IS1 ASSURITY MRI
-- MNP match: PACEMAKER CARDIAC ASSURITY MRI IMPLANTABLE ... 2-CHAMBER IS-1
-- Score: 80 (HIGH) | AP rows: 6
INSERT INTO {SCHEMA}.`PO_Master_PP_CA_449_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'PACEMAKER CARDIAC ASSURITY MRI IMPLANTABLE 50MM X 47MM 6MM THK 10.4ML 20GM 2-CHAMBER IS-1 CONNECTOR RF TELEMETRY MRI-CONDITIONAL',
    'PP-CA-449',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_CA_449_v1 ap
WHERE ap.seq_no IN (150252, 162146, 162147, 180766, 180769, 1334089)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_CA_449_v1` WHERE INV_seq_no IS NOT NULL);


-- DEFIBRILLATOR CARDIAC DUAL CHAMBER IS1 DF4 GALLANTDR
-- MNP match: DEFIBRILLATOR CARDIAC GALLANT DR
-- Score: 80 (HIGH) | AP rows: 2
INSERT INTO {SCHEMA}.`PO_Master_PP_CA_449_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'DEFIBRILLATOR CARDIAC GALLANT DR',
    'PP-CA-449',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_CA_449_v1 ap
WHERE ap.seq_no IN (180773, 914432)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_CA_449_v1` WHERE INV_seq_no IS NOT NULL);


-- DEFIBRILLATOR CARDIAC IS1 IS4 DF4 GALLANTHF
-- MNP match: DEFIBRILLATOR CARDIAC GALLANT HF
-- Score: 67 (MEDIUM — reviewed & approved) | AP rows: 3
INSERT INTO {SCHEMA}.`PO_Master_PP_CA_449_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'DEFIBRILLATOR CARDIAC GALLANT HF',
    'PP-CA-449',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_CA_449_v1 ap
WHERE ap.seq_no IN (180776, 917158, 917164)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_CA_449_v1` WHERE INV_seq_no IS NOT NULL);


-- LEAD PACING J SHAPED BIPOLAR TINES FIXATION IS1 ISOFLEX OPTIM 46CM
-- MNP match: LEAD PACING ISOFLEX BIPOLAR 7FR 46CM ... IS-1 CONNECTOR OPTIM
-- Score: 83 (HIGH) | AP rows: 1
INSERT INTO {SCHEMA}.`PO_Master_PP_CA_449_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'LEAD PACING ISOFLEX BIPOLAR 7FR 46CM 10MM SPACING ATRIAL VENTRICULAR J-TIP STEROID ELUTING TINED FIXATION IS-1 CONNECTOR OPTIM',
    'PP-CA-449',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_CA_449_v1 ap
WHERE ap.seq_no IN (939216)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_CA_449_v1` WHERE INV_seq_no IS NOT NULL);


-- LEAD PACING J SHAPED BIPOLAR TINES FIXATION IS1 ISOFLEX OPTIM 52CM
-- MNP match: LEAD PACING ISOFLEX BIPOLAR 7FR 52CM ... IS-1 CONNECTOR OPTIM
-- Score: 83 (HIGH) | AP rows: 1
INSERT INTO {SCHEMA}.`PO_Master_PP_CA_449_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'LEAD PACING ISOFLEX BIPOLAR 7FR 52CM 10MM SPACING ATRIAL VENTRICULAR STRAIGHT STEROID ELUTING TINED FIXATION IS-1 CONNECTOR OPTIM',
    'PP-CA-449',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_CA_449_v1 ap
WHERE ap.seq_no IN (973492)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_CA_449_v1` WHERE INV_seq_no IS NOT NULL);


-- LEAD PACING STRAIGHT BIPOLAR TINES FIXATION IS1 ISOFLEX OPTIM 58CM
-- MNP match: LEAD PACING ISOFLEX BIPOLAR 7FR 58CM ... IS-1 CONNECTOR OPTIM
-- Score: 92 (HIGH) | AP rows: 1
INSERT INTO {SCHEMA}.`PO_Master_PP_CA_449_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'LEAD PACING ISOFLEX BIPOLAR 7FR 58CM 10MM SPACING ATRIAL VENTRICULAR STRAIGHT STEROID ELUTING TINED FIXATION IS-1 CONNECTOR OPTIM',
    'PP-CA-449',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_CA_449_v1 ap
WHERE ap.seq_no IN (939217)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_CA_449_v1` WHERE INV_seq_no IS NOT NULL);


-- LEAD PACING HEART QUADRIPOLAR PASSIVE FIXATION S CURVE QUARTET LEFT 86CM
-- MNP match: LEAD, QUARTET QUADRIPOLAR 1458Q/86
-- Score: 72 (MEDIUM — reviewed & approved) | AP rows: 1
INSERT INTO {SCHEMA}.`PO_Master_PP_CA_449_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'LEAD, QUARTET QUADRIPOLAR 1458Q/86',
    'PP-CA-449',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_CA_449_v1 ap
WHERE ap.seq_no IN (180779)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_CA_449_v1` WHERE INV_seq_no IS NOT NULL);


-- ── PP-LA-524 ─────────────────────────────────────────────────────────────

-- TESTPACK TROPONIN T G5 STAT ELECSYS COBAS E 100 V2
-- MNP match: TROPONIN T G5 STAT ELECSYS COBAS E100 V2
-- Score: 93 (HIGH) | AP rows: 12
INSERT INTO {SCHEMA}.`PO_Master_PP_LA_524_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'TROPONIN T G5 STAT ELECSYS COBAS E100 V2',
    'PP-LA-524',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_LA_524_v1 ap
WHERE ap.seq_no IN (877790, 892608, 919879, 936114, 980013, 995455, 995477,
                    1027492, 1055321, 1056725, 1072703, 1095286)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_LA_524_v1` WHERE INV_seq_no IS NOT NULL);


-- TESTPACK PROBNP G2 STAT 100
-- MNP match: TESTPACK, PROBNP G2 STAT (100)
-- Score: 95 (HIGH) | AP rows: 2
INSERT INTO {SCHEMA}.`PO_Master_PP_LA_524_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'TESTPACK, PROBNP G2 STAT (100)',
    'PP-LA-524',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_LA_524_v1 ap
WHERE ap.seq_no IN (919878, 1011665)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_LA_524_v1` WHERE INV_seq_no IS NOT NULL);


-- TESTPACK COBAS EELECSYS PROBNP G2 100 V21
-- MNP match: PROBNP G2 STAT ELECSYS COBAS E 100 V2.1
-- Score: 90 (HIGH) | AP rows: 7  | Note: EELECSYS is a typo in AP source data
INSERT INTO {SCHEMA}.`PO_Master_PP_LA_524_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'PROBNP G2 STAT ELECSYS COBAS E 100 V2.1',
    'PP-LA-524',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_LA_524_v1 ap
WHERE ap.seq_no IN (877781, 929702, 936113, 995472, 1001695, 1001700, 1059545)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_LA_524_v1` WHERE INV_seq_no IS NOT NULL);


-- CALIBRATOR TROPONIN T G5 STAT CS ELECSYS 4 X 1ML
-- MNP match: TROPONIN T GEN 5 STAT CS ELECSYS
-- Score: 91 (HIGH) | AP rows: 6
INSERT INTO {SCHEMA}.`PO_Master_PP_LA_524_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'TROPONIN T GEN 5 STAT CS ELECSYS',
    'PP-LA-524',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_LA_524_v1 ap
WHERE ap.seq_no IN (882623, 910291, 995429, 1038320, 1056727, 1095287)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_LA_524_v1` WHERE INV_seq_no IS NOT NULL);


-- CALIBRATOR PROBNP G2 CS ELSCSYS V21
-- MNP match: CALIBRATOR, PROBNP STAT CS ELECSYS (4 X 1ML)
-- Score: 73 (MEDIUM — reviewed & approved) | Note: ELSCSYS is a typo in AP source data
INSERT INTO {SCHEMA}.`PO_Master_PP_LA_524_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'CALIBRATOR, PROBNP STAT CS ELECSYS (4 X 1ML)',
    'PP-LA-524',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_LA_524_v1 ap
WHERE ap.seq_no IN (877780, 929703, 995424, 1023338, 1056726)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_LA_524_v1` WHERE INV_seq_no IS NOT NULL);


-- CONTROL CHEMISTRY PRECI MULTIMARKER COBAS 6X2ML
-- MNP match: CONTROL CHEMISTRY PRECI VARIA 6X3ML
-- Score: 79 (MEDIUM — reviewed & approved) | AP rows: 3
INSERT INTO {SCHEMA}.`PO_Master_PP_LA_524_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'CONTROL CHEMISTRY PRECI VARIA 6X3ML',
    'PP-LA-524',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_LA_524_v1 ap
WHERE ap.seq_no IN (986774, 1192142, 1218722)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_LA_524_v1` WHERE INV_seq_no IS NOT NULL);


-- ── PP-NS-1610 ────────────────────────────────────────────────────────────

-- CANISTER SUCTION CONNECTOR PREVENA PLUS 150ML
-- MNP match: CANISTER, PREVENA WITH PLUS CONNECTOR 150ML
-- Score: 89 (HIGH) | AP rows: 2
INSERT INTO {SCHEMA}.`PO_Master_PP_NS_1610_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'CANISTER, PREVENA WITH PLUS CONNECTOR 150ML',
    'PP-NS-1610',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_NS_1610_v1 ap
WHERE ap.seq_no IN (907263, 961236)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_NS_1610_v1` WHERE INV_seq_no IS NOT NULL);


-- T.R.A.C. Y-CONNECTOR CASE 10
-- Score: 51 (LOW) — NO INSERT — manual MNP master enrichment required first
-- seq_nos: 900326, 958364
-- Action: Add 'T.R.A.C. Y-CONNECTOR CASE 10' as alternate description in MNP master,
--         then re-run extension pipeline E5 to pick up via description match.
-- =============================================================================


-- ── PP-OR-1487 ────────────────────────────────────────────────────────────

-- PAN DUST LOBBY WITH HANDLE BLACK 12X10X6IN
-- MNP match: DUSTPAN, LOBBY WITH HANDLE - BLACK
-- Score: 84 (HIGH) | AP rows: 4
INSERT INTO {SCHEMA}.`PO_Master_PP_OR_1487_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'DUSTPAN, LOBBY WITH HANDLE - BLACK',
    'PP-OR-1487',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_OR_1487_v1 ap
WHERE ap.seq_no IN (481, 137644, 1160292, 1167554)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_OR_1487_v1` WHERE INV_seq_no IS NOT NULL);


-- APPLIER CLIP LATEX SURGICLIP III 9IN
-- MNP match: APPLIER CLIP PREMIUM SURGICLIP III OPEN AUTOMATIC 9IN...
-- Score: 91 (HIGH) | AP rows: 1
INSERT INTO {SCHEMA}.`PO_Master_PP_OR_1487_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'APPLIER CLIP PREMIUM SURGICLIP III OPEN AUTOMATIC 9IN PRELOADED LIGATING ERGONOMIC HANDLE BLACK SINGLE-USE F/20-SMALL SUPER INTERLOCK TITANIUM CLIP 6/BX',
    'PP-OR-1487',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_OR_1487_v1 ap
WHERE ap.seq_no IN (1218875)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_OR_1487_v1` WHERE INV_seq_no IS NOT NULL);


-- APPLIER CLIP TITANIUM LATEX FREE PREMIUM SURGICLIP LARGE 13IN
-- MNP match: APPLIER CLIP PREMIUM SURGICLIP OPEN AUTOMATIC 13IN...
-- Score: 90 (HIGH) | AP rows: 1
INSERT INTO {SCHEMA}.`PO_Master_PP_OR_1487_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'APPLIER CLIP PREMIUM SURGICLIP OPEN AUTOMATIC 13IN ERGONOMIC HANDLE GREEN LATEX-FREE DEHP-FREE STERILE SINGLE-USE F/15-SUPER INTERNAL INTERLOCK LARGE TITANIUM CLIP VETERINARY 6/BX',
    'PP-OR-1487',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_OR_1487_v1 ap
WHERE ap.seq_no IN (1218874)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_OR_1487_v1` WHERE INV_seq_no IS NOT NULL);


-- APPLIER CLIP LATEX FREE DISPOSABLE PREMIUM SURGICLIP MEDIUM 9.75IN
-- MNP match: PREMIUM SURGICLIP II 9.75
-- Score: 81 (HIGH) | AP rows: 1
INSERT INTO {SCHEMA}.`PO_Master_PP_OR_1487_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'PREMIUM SURGICLIP II 9.75',
    'PP-OR-1487',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_OR_1487_v1 ap
WHERE ap.seq_no IN (1220034)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_OR_1487_v1` WHERE INV_seq_no IS NOT NULL);


-- DEVICE SUTURING LATEX FREE STERILE ENDO CLOSE
-- MNP match: TROCAR, ENDO CLOSE
-- Score: 71 (MEDIUM — reviewed & approved) | AP rows: 3
INSERT INTO {SCHEMA}.`PO_Master_PP_OR_1487_v1`
    (INV_seq_no, INV_Description, Facility_Product_Description,
     Contract_Number, INV_Extended_Spend_actual, PO_Base_Spend_actual, Matched_Flag)
SELECT
    ap.seq_no,
    ap.Line_Description,
    'TROCAR, ENDO CLOSE',
    'PP-OR-1487',
    CASE WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount) ELSE ap.Extended_Amount END,
    0,
    'MNP_Similarity_Match'
FROM {SCHEMA}.AP_Data_v4_dedup_PP_OR_1487_v1 ap
WHERE ap.seq_no IN (880605, 912509, 1021891)
  AND ap.seq_no NOT IN (SELECT INV_seq_no FROM {SCHEMA}.`PO_Master_PP_OR_1487_v1` WHERE INV_seq_no IS NOT NULL);


-- =============================================================================
-- SUMMARY OF INSERTS
-- =============================================================================
-- Contract       | Descriptions | AP Rows Inserted | Excluded (low score)
-- PP-CA-449      |      7       |       15         |      0
-- PP-LA-524      |      6       |       35         |      0
-- PP-NS-1610     |      1       |        2         |      1 (T.R.A.C. Y-CONNECTOR)
-- PP-OR-1487     |      5       |       10         |      0
-- ─────────────────────────────────────────────────────────────────────────────
-- TOTAL          |     19       |       62         |      1
-- =============================================================================
