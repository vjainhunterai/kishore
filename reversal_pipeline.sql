-- =====================================================================
-- DUPLICATE-AP REVERSAL PIPELINE  (single step-wise script)
-- ---------------------------------------------------------------------
-- Purpose : For confirmed duplicate AP anomalies, find whether a reversal
--           transaction exists in the SOURCE AP data. If found, take that
--           source record, stamp it with the duplicate pair's
--           new_matched_record_number, and INSERT it into the anomaly
--           table as the reversal line.
--
-- Tables  : anomaly.duplicate_ap_invoice   (confirmed duplicates)
--           l1_t0004_db.temp_ap_inv        (source AP data)
--           l3_dm_db.dim_vendor            (vendor alias lookup)
--
-- Reversal = a SEPARATE source line, same supplier, amount offsets the
--            duplicate ( -dup_amt = src_amt ), nearest by invoice date.
--            (See STEP 4 to also promote void/cancel/adjustment reversals.)
--
-- Run order: STEP 1 -> STEP 6 in sequence.
-- =====================================================================


-- =====================================================================
-- STEP 1 : Clean up any temp tables from a previous run
-- =====================================================================
DROP TABLE IF EXISTS anomaly.duplicate_ap_invoice_temp3;
DROP TABLE IF EXISTS anomaly.duplicate_ap_invoice_temp4;
DROP TABLE IF EXISTS anomaly.duplicate_ap_invoice_temp5;
DROP TABLE IF EXISTS anomaly.reversal_to_insert;


-- =====================================================================
-- STEP 2 : Enrich confirmed anomalies with their own source amount
--          (temp3 = duplicate rows + matching source INVOICE_AMOUNT)
-- =====================================================================
CREATE TABLE anomaly.duplicate_ap_invoice_temp3 AS
SELECT a.*
FROM anomaly.CCHS_AnomalyHunt_Reversal_dates_request a
INNER JOIN l1_t0004_db.temp_ap_inv_delaware_all_year_data b
  ON a.seq_no = b.SEQ_NO


-- =====================================================================
-- STEP 3 : Prepare the source AP table for matching
--          (temp4 = source rows, vendor-aliased, numeric-cleaned inv no)
-- =====================================================================
CREATE TABLE anomaly.duplicate_ap_invoice_temp4 AS
SELECT a.SEQ_NO,
       a.SUPPLIERS_INVOICE_NUMBER,
       COALESCE(CAST(REGEXP_REPLACE(a.SUPPLIERS_INVOICE_NUMBER, '[^0-9]+', '') AS DECIMAL(65,0)), -99)
         AS cleaned_Supplier_Invoice_Number,
       b.VENDOR_NAME_ALIAS,
       a.SUPPLIER,
       a.INVOICE_AMOUNT,
       a.INVOICE_DATE
FROM l1_t0004_db.temp_ap_inv_delaware_all_year_data a
LEFT JOIN l3_dm_db.dim_vendor b
  ON a.SUPPLIER = b.vendor_name;


-- =====================================================================
-- STEP 4 : Find the reversal source record for each duplicate pair.
--          For each new_matched_record_number, pick the single offsetting
--          source line ( -dup_amt = src_amt ), nearest by invoice date.
--          (temp5 = candidate reversals ; reversal_to_insert = the winner)
-- =====================================================================
CREATE TABLE anomaly.duplicate_ap_invoice_temp5 AS
SELECT a.new_matched_record_number,
       a.seq_no            AS anomaly_seq_no,
       b.SEQ_NO            AS reversal_seq_no,
       b.INVOICE_AMOUNT    AS reversal_amount,
       b.INVOICE_DATE      AS reversal_date,
       ROW_NUMBER() OVER (
           PARTITION BY a.new_matched_record_number
           ORDER BY ABS(DATEDIFF(a.Invoice_Date, b.INVOICE_DATE)) ASC
       ) AS rnk
FROM anomaly.duplicate_ap_invoice_temp3 a
INNER JOIN anomaly.duplicate_ap_invoice_temp4 b
  ON  a.Supplier         =  b.SUPPLIER
  AND -(a.Invoice_amount) =  b.INVOICE_AMOUNT     -- offsetting amount = reversal
  AND a.seq_no           <> b.SEQ_NO;

-- keep one reversal per duplicate group
CREATE TABLE anomaly.reversal_to_insert AS
SELECT new_matched_record_number,
       reversal_seq_no
FROM anomaly.duplicate_ap_invoice_temp5
WHERE rnk = 1;


-- =====================================================================
-- STEP 5 : INSERT the source reversal record into the anomaly table,
--          carrying the duplicate pair's new_matched_record_number and
--          flagged as a reversal. NOT EXISTS prevents double-insert.
-- =====================================================================
INSERT INTO anomaly.CCHS_AnomalyHunt_Reversal_dates_request (
    seq_no,
    new_matched_record_number,
    Invoice_amount,
    Extended_amount,
    Supplier,
    Supplier_ID,
    Invoice_Number,
    Supplier_Invoice_Number,
    Created_On,
    Invoice_Date,
    Line_Description,
    Check_Number,
    External_PO_Number,
    reversal_flag,
    Settlement_Run_Number,
    Document_Link,
    DOCUMENT_PAYMENT_STATUS,
    Payment_Type,
    PAYMENT_DATE,
    COMPANY,
    MEMO,
    LOCATION,
    INVOICE_STATUS,
    Reason_Grouped
)
SELECT s.SEQ_NO,
       r.new_matched_record_number,            -- SAME pair number
       s.INVOICE_AMOUNT,
       s.EXTENDED_AMOUNT,
       s.SUPPLIER,
       s.SUPPLIER_ID,
       s.INVOICE_NUMBER,
       s.SUPPLIERS_INVOICE_NUMBER,
       s.CREATED_ON,
       s.INVOICE_DATE,
       s.LINE_DESCRIPTION,
       s.CHECK_NUMBER,
       s.EXTERNAL_PO_NUMBER,
       1 AS reversal_flag,                      -- this injected row IS the reversal
       s.SETTLEMENT_RUN_NUMBER,
       s.DOCUMENT_LINK,
       s.DOCUMENT_PAYMENT_STATUS,
       s.PAYMENT_TYPE,
       s.PAYMENT_DATE,
       s.COMPANY,
       s.MEMO,
       s.LOCATION,
       s.INVOICE_STATUS,
       'Reversal' AS Reason_Grouped             -- so BI can tell it apart
FROM anomaly.reversal_to_insert r
INNER JOIN l1_t0004_db.temp_ap_inv_delaware_all_year_data s
  ON r.reversal_seq_no = s.SEQ_NO
WHERE NOT EXISTS (
    SELECT 1
    FROM anomaly.CCHS_AnomalyHunt_Reversal_dates_request d
    WHERE d.new_matched_record_number = r.new_matched_record_number
      AND d.seq_no = s.SEQ_NO
);


-- =====================================================================
-- STEP 6 : (optional) verify the result, then clean up temp tables
-- =====================================================================
-- SELECT new_matched_record_number,
--        COUNT(*)                                              AS rows_in_group,
--        SUM(CASE WHEN reversal_flag = 1 THEN 1 ELSE 0 END)    AS reversal_rows
-- FROM anomaly.duplicate_ap_invoice
-- WHERE new_matched_record_number IN (SELECT new_matched_record_number FROM anomaly.reversal_to_insert)
-- GROUP BY new_matched_record_number
-- ORDER BY new_matched_record_number;

DROP TABLE IF EXISTS anomaly.duplicate_ap_invoice_temp3;
DROP TABLE IF EXISTS anomaly.duplicate_ap_invoice_temp4;
DROP TABLE IF EXISTS anomaly.duplicate_ap_invoice_temp5;
-- keep anomaly.reversal_to_insert if BI/audit wants the mapping; else drop:
-- DROP TABLE IF EXISTS anomaly.reversal_to_insert;
