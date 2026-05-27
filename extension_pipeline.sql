{CONTRACT_NAME}
      ↓
E1: Contract_Group  →  find Contract_ID → get ALL sibling Contract_Numbers + dates
      ↓
E2: MNP_Pool        →  all description_text variants for those contracts
      ↓
E3: DateRange       →  MIN(effective) / MAX(expiration) single reference row
      ↓
E4: AP_Data_Ext     →  reuse existing vendor-deduped AP pool
                        + filter Invoice_Date within date range
                        + exclude seq_nos already in PO_Master
      ↓
E5: AP_MNP_Matched  →  prefix match: LEFT(Line_Description, len(desc)) = desc_text
                        ROW_NUMBER to keep longest/best match per AP seq_no
      ↓
E6: INSERT          →  into PO_Master with Matched_Flag = 'MNP_Desc_Match'
                        PO-side columns = NULL (no PO line, AP-only match)
      ↓
E7: Cleanup         →  drop all 5 intermediate tables



-- =============================================================================
-- PO-AP INTEGRATION: EXTENSION PIPELINE (MNP Description Match)
-- =============================================================================
-- PURPOSE  : Runs AFTER the existing pipeline. Finds additional AP records
--            missed by the core pipeline by using:
--              1. All sibling Contract Numbers under the same Contract_ID
--              2. Merged date range (MIN effective → MAX expiration)
--              3. All MNP description_text variants matched against AP Line_Description
-- INPUT    : {SCHEMA}, {CONTRACT_NAME}, {table_name}  (same params as core pipeline)
-- OUTPUT   : New rows inserted into {SCHEMA}.PO_Master_{table_name}_v1
--            with Matched_Flag = 'MNP_Desc_Match'
-- NOTE     : Already-matched AP seq_nos (from core pipeline) are excluded
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP E1: Build Contract Group Date Range
-- -----------------------------------------------------------------------------
-- Starting from {CONTRACT_NAME}, resolve its Contract_ID,
-- then collect ALL sibling Contract_Numbers under that same ID
-- and derive the merged date window across all of them.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS {SCHEMA}.Contract_Group_{table_name}_v1;

CREATE TABLE {SCHEMA}.Contract_Group_{table_name}_v1 AS
SELECT
    c.Contract_ID,
    c.Contract_Number,
    c.Contract_Effective_Date,
    c.Contract_Expiration_Date
FROM contract_master c
WHERE c.Contract_ID = (
    SELECT Contract_ID
    FROM contract_master
    WHERE Contract_Number = '{CONTRACT_NAME}'
    LIMIT 1
);

-- -----------------------------------------------------------------------------
-- STEP E2: Build MNP Description Pool
-- -----------------------------------------------------------------------------
-- Collect ALL distinct description_text variants from MNP_master
-- for every Contract_Number in the resolved contract group.
-- One MPN id can appear across multiple contract numbers — all are included.
-- Deduplicate on description_text to avoid redundant match attempts.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS {SCHEMA}.MNP_Pool_{table_name}_v1;

-- Step E2 FIXED: deduplicate descriptions, prefer input contract_no
CREATE TABLE {SCHEMA}.MNP_Pool_{table_name}_v1 AS
SELECT DISTINCT
    m.id                AS mnp_id,
    m.mpn_normalized,
    m.description_text,
    m.manufacturer_raw,
    m.source_field,
    m.source_system,
    -- Prefer the input contract_no; fall back to whichever other sibling
    CASE 
        WHEN m.contract_no = '{CONTRACT_NAME}' THEN m.contract_no
        ELSE m.contract_no
    END                 AS contract_no
FROM MNP_master m
WHERE m.contract_no IN (
    SELECT Contract_Number
    FROM {SCHEMA}.Contract_Group_{table_name}_v1
)
-- Deduplicate: for same description, keep only one row (longest mpn_normalized wins)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY m.description_text
    ORDER BY 
        CASE WHEN m.contract_no = '{CONTRACT_NAME}' THEN 0 ELSE 1 END ASC,
        LENGTH(m.mpn_normalized) DESC
) = 1;

-- -----------------------------------------------------------------------------
-- STEP E3: Resolve Group Date Range (single-row reference table)
-- -----------------------------------------------------------------------------
-- MIN(effective) → MAX(expiration) across all sibling contracts.
-- This is the window within which AP Invoice_Date must fall.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS {SCHEMA}.Contract_DateRange_{table_name}_v1;

CREATE TABLE {SCHEMA}.Contract_DateRange_{table_name}_v1 AS
SELECT
    MIN(Contract_Effective_Date)  AS group_start_date,
    MAX(Contract_Expiration_Date) AS group_end_date
FROM {SCHEMA}.Contract_Group_{table_name}_v1;

-- -----------------------------------------------------------------------------
-- STEP E4: Filter AP Data by Vendor + Date Range (Extension AP Pool)
-- -----------------------------------------------------------------------------
-- Reuse the already-deduplicated AP vendor pool from the core pipeline
-- (AP_Data_v4_dedup_{table_name}_v1) — no need to redo vendor alias lookup.
-- Apply date range filter on Invoice_Date using the group date window.
-- Exclude any AP seq_nos already matched in the core pipeline.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS {SCHEMA}.AP_Data_Ext_{table_name}_v1;

CREATE TABLE {SCHEMA}.AP_Data_Ext_{table_name}_v1 AS
SELECT ap.*
FROM {SCHEMA}.AP_Data_v4_dedup_{table_name}_v1 ap
CROSS JOIN {SCHEMA}.Contract_DateRange_{table_name}_v1 dr
WHERE
    -- Date range filter: Invoice_Date must fall within the contract group window
    ap.Invoice_Date BETWEEN dr.group_start_date AND dr.group_end_date
    -- Exclude records already captured by the core pipeline
    AND ap.seq_no NOT IN (
        SELECT DISTINCT INV_seq_no
        FROM {SCHEMA}.`PO_Master_{table_name}_v1`
        WHERE INV_seq_no IS NOT NULL
    );

-- -----------------------------------------------------------------------------
-- STEP E5: MNP Description Match → AP Lines
-- -----------------------------------------------------------------------------
-- Match AP Line_Description against all MNP description_text variants.
-- Match logic mirrors the core pipeline's prefix match:
--   LEFT(ap.Line_Description, LENGTH(mnp.description_text)) = mnp.description_text
-- This means: AP line description must START WITH the MNP description text.
-- One AP line may match multiple MNP descriptions — ROW_NUMBER deduplicates
-- to keep only the best (longest description) match per AP seq_no.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS {SCHEMA}.AP_MNP_Matched_{table_name}_v1;

CREATE TABLE {SCHEMA}.AP_MNP_Matched_{table_name}_v1 AS
SELECT *
FROM (
    SELECT
        ap.seq_no                   AS INV_seq_no,
        ap.Invoice_Date             AS INV_Date,
        ap.Suppliers_Invoice_Number,
        ap.Supplier                 AS INV_Vendor_Name,
        ap.External_PO_Number,
        ap.Purchase_Orders,
        COALESCE(ap.External_PO_Number, ap.Purchase_Orders) AS INV_PO_Number,
        ap.Line_Description         AS INV_Description,
        ap.Quantity                 AS INV_Quantity,
        CASE
            WHEN ap.Invoice_Amount < 0 THEN -ABS(ap.Extended_Amount)
            ELSE ap.Extended_Amount
        END                         AS INV_Extended_Spend,
        ap.Unit_Cost                AS INV_Base_Price,

        -- MNP side columns (for traceability)
        mnp.mnp_id,
        mnp.mpn_normalized,
        mnp.description_text        AS MNP_Description_Matched,
        mnp.manufacturer_raw        AS MNP_Manufacturer,
        mnp.contract_no             AS MNP_Contract_No,

        -- Rank: prefer longest description match per AP line
        -- (longer description = more specific / better match)
        ROW_NUMBER() OVER (
            PARTITION BY ap.seq_no
            ORDER BY LENGTH(mnp.description_text) DESC
        ) AS match_rnk

    FROM {SCHEMA}.AP_Data_Ext_{table_name}_v1 ap
    INNER JOIN {SCHEMA}.MNP_Pool_{table_name}_v1 mnp
        ON  TRIM(LEFT(ap.Line_Description, LENGTH(mnp.description_text))) = TRIM(mnp.description_text)
AND LENGTH(mnp.description_text) >= 10   -- minimum chars to be a meaningful match

) ranked
WHERE match_rnk = 1;   -- Keep best match per AP line only

-- -----------------------------------------------------------------------------
-- STEP E6: Insert Extension Records into PO_Master
-- -----------------------------------------------------------------------------
-- AP lines matched via MNP descriptions are inserted with:
--   - PO-side columns as NULL (no PO line directly linked)
--   - INV_Extended_Spend_actual = full amount (first and only match)
--   - Matched_Flag = 'MNP_Desc_Match'
-- Guard: exclude any seq_no that got matched in a previous extension run
--        (safe to re-run the extension pipeline idempotently)
-- -----------------------------------------------------------------------------

INSERT INTO {SCHEMA}.`PO_Master_{table_name}_v1`
(
    `PO_seq_no`,
    `INV_seq_no`,
    `PO_Number_common`,
    `PO_Number`,
    `INV_PO_Number`,
    `PO_Date`,
    `INV_Date`,
    `Suppliers_Invoice_Number`,
    `PO_Vendor_Name`,
    `INV_Vendor_Name`,
    `PO_Line`,
    `INV_PO_Line`,
    `PO_Description`,
    `INV_Description`,
    `MRN`,
    `Facility_Product_Description`,
    `Contract_Number`,
    `Contract_Name`,
    `Contracted_Supplier`,
    `PO_Quantity`,
    `INV_Quantity`,
    `PO_Base_Spend`,
    `INV_Extended_Spend`,
    `PO_Base_Price`,
    `INV_Base_Price`,
    `PO_Base_Spend_actual`,
    `INV_Extended_Spend_actual`,
    `Matched_Flag`
)
SELECT
    NULL                        AS PO_seq_no,
    m.INV_seq_no,
    m.INV_PO_Number             AS PO_Number_common,
    NULL                        AS PO_Number,
    m.INV_PO_Number,
    NULL                        AS PO_Date,
    m.INV_Date,
    m.Suppliers_Invoice_Number,
    NULL                        AS PO_Vendor_Name,
    m.INV_Vendor_Name,
    NULL                        AS PO_Line,
    NULL                        AS INV_PO_Line,
    NULL                        AS PO_Description,
    m.INV_Description,
    m.mpn_normalized            AS MRN,
    m.MNP_Description_Matched   AS Facility_Product_Description,
    m.MNP_Contract_No           AS Contract_Number,
    NULL                        AS Contract_Name,
    NULL                        AS Contracted_Supplier,
    NULL                        AS PO_Quantity,
    m.INV_Quantity,
    NULL                        AS PO_Base_Spend,
    m.INV_Extended_Spend,
    NULL                        AS PO_Base_Price,
    m.INV_Base_Price,
    0                           AS PO_Base_Spend_actual,
    m.INV_Extended_Spend        AS INV_Extended_Spend_actual,
    'MNP_Desc_Match'            AS Matched_Flag

FROM {SCHEMA}.AP_MNP_Matched_{table_name}_v1 m
WHERE m.INV_seq_no NOT IN (
    -- Final safety guard: exclude anything already in PO_Master
    -- (covers core pipeline + any prior extension run)
    SELECT DISTINCT INV_seq_no
    FROM {SCHEMA}.`PO_Master_{table_name}_v1`
    WHERE INV_seq_no IS NOT NULL
);

-- -----------------------------------------------------------------------------
-- STEP E7: Cleanup Intermediate Extension Tables
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS {SCHEMA}.Contract_Group_{table_name}_v1;
DROP TABLE IF EXISTS {SCHEMA}.MNP_Pool_{table_name}_v1;
DROP TABLE IF EXISTS {SCHEMA}.Contract_DateRange_{table_name}_v1;
DROP TABLE IF EXISTS {SCHEMA}.AP_Data_Ext_{table_name}_v1;
DROP TABLE IF EXISTS {SCHEMA}.AP_MNP_Matched_{table_name}_v1;

-- =============================================================================
-- EXTENSION PIPELINE COMPLETE
-- New AP records with Matched_Flag = 'MNP_Desc_Match' added to PO_Master
-- =============================================================================
