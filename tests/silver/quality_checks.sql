/*
=============================================================
Silver Layer - Data Quality Checks
=============================================================
Purpose:
    Validates the quality, consistency, and integrity of
    data loaded into the Silver layer.

    These checks are intended to identify:
        - NULL values
        - Duplicate keys
        - Invalid standardized values
        - Invalid dates
        - Referential integrity issues
        - Business rule violations
        - Data standardization issues

Expected Result:
    Each validation query should return NO rows unless
    otherwise stated.

Note:
    This script is intended for development, testing,
    and data-validation purposes.
=============================================================
*/


-- =========================================================
-- CRM CUSTOMER
-- =========================================================

-- ---------------------------------------------------------
-- Check for NULL or Duplicate Customer IDs
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- ---------------------------------------------------------
-- Check for Unwanted Spaces in Customer Names
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname);


-- ---------------------------------------------------------
-- Check Gender Standardization
-- Expectation: Male / Female / n/a
-- ---------------------------------------------------------

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;


-- ---------------------------------------------------------
-- Check Marital Status Standardization
-- Expectation: Married / Single / n/a
-- ---------------------------------------------------------

SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;


-- =========================================================
-- CRM PRODUCT
-- =========================================================

-- ---------------------------------------------------------
-- Check for NULL or Duplicate Product IDs
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- ---------------------------------------------------------
-- Check Product Line Standardization
-- Expectation:
--     Mountain / Road / other Sales / Touring / n/a
-- ---------------------------------------------------------

SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- ---------------------------------------------------------
-- Check for Invalid Product Date Ranges
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    prd_id,
    prd_key,
    prd_start_dt,
    prd_end_dt
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;


-- =========================================================
-- CRM SALES
-- =========================================================

-- ---------------------------------------------------------
-- Check for NULL or Duplicate Order Numbers
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    COUNT(*) AS record_count
FROM silver.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1
    OR sls_ord_num IS NULL;


-- ---------------------------------------------------------
-- Check for Unwanted Spaces in Order Numbers
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num <> TRIM(sls_ord_num);


-- ---------------------------------------------------------
-- Check Product and Customer Referential Integrity
--
-- Expectation:
--     Every sales product key should exist in
--     silver.crm_prd_info.
--
--     Every customer ID should exist in
--     silver.crm_cust_info.
--
-- Note:
--     NULL values are checked separately to avoid
--     NOT IN / NULL behavior.
-- ---------------------------------------------------------

SELECT
    s.sls_ord_num,
    s.sls_prd_key,
    s.sls_cust_id
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_prd_info p
    ON s.sls_prd_key = p.prd_key
LEFT JOIN silver.crm_cust_info c
    ON s.sls_cust_id = c.cst_id
WHERE p.prd_key IS NULL
   OR c.cst_id IS NULL;


-- ---------------------------------------------------------
-- Check for NULL Product Keys or Customer IDs
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id
FROM silver.crm_sales_details
WHERE sls_prd_key IS NULL
   OR sls_cust_id IS NULL;


-- ---------------------------------------------------------
-- Check for Invalid Order Dates
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL
  AND (
        sls_order_dt < '1900-01-01'
        OR sls_order_dt > '2050-01-01'
      );


-- ---------------------------------------------------------
-- Check for Invalid Ship Dates
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt IS NOT NULL
  AND (
        sls_ship_dt < '1900-01-01'
        OR sls_ship_dt > '2050-01-01'
      );


-- ---------------------------------------------------------
-- Check for Invalid Due Dates
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt IS NOT NULL
  AND (
        sls_due_dt < '1900-01-01'
        OR sls_due_dt > '2050-01-01'
      );


-- ---------------------------------------------------------
-- Check Order Date vs Ship Date / Due Date
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;


-- ---------------------------------------------------------
-- Check Ship Date vs Due Date
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt > sls_due_dt;


-- ---------------------------------------------------------
-- Check Sales Business Rule
--
-- Expected:
--     Sales = Quantity × Price
--     Sales > 0
--     Quantity > 0
--     Price > 0
--     No NULL values
--
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    sls_ord_num,
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;


-- =========================================================
-- ERP CUSTOMER
-- =========================================================

-- ---------------------------------------------------------
-- Check CRM ↔ ERP Customer Key Consistency
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    e.cid
FROM silver.erp_cust_az12 e
LEFT JOIN silver.crm_cust_info c
    ON e.cid = c.cst_key
WHERE c.cst_key IS NULL;


-- ---------------------------------------------------------
-- Check Customer Birth Date Range
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-02'
   OR bdate > CAST(GETDATE() AS DATE);


-- ---------------------------------------------------------
-- Check Gender Standardization
-- Expectation: Male / Female / n/a
-- ---------------------------------------------------------

SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;


-- =========================================================
-- ERP LOCATION
-- =========================================================

-- ---------------------------------------------------------
-- Check CRM ↔ ERP Customer Key Consistency
--
-- The comparison uses the transformed ERP CID,
-- where '-' has been removed.
--
-- Expectation: No Results
-- ---------------------------------------------------------

SELECT
    REPLACE(e.cid, '-', '') AS cid
FROM bronze.erp_loc_a101 e
LEFT JOIN silver.crm_cust_info c
    ON REPLACE(e.cid, '-', '') = c.cst_key
WHERE c.cst_key IS NULL;


-- ---------------------------------------------------------
-- Check Country Standardization
-- Expectation:
--     Standardized country values should be reviewed
--     for unexpected values.
-- ---------------------------------------------------------

SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- =========================================================
-- ERP PRODUCT CATEGORY
-- =========================================================

-- ---------------------------------------------------------
-- No transformation-specific quality checks were supplied
-- for this table.
--
-- The table currently receives data directly from Bronze.
-- Additional checks can be introduced if business rules
-- for category, subcategory, or maintenance are defined.
-- ---------------------------------------------------------
