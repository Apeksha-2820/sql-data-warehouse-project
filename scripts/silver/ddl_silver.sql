/*
=============================================================
Load Silver Layer
=============================================================
Purpose:
    Loads cleaned, standardized, and transformed data from
    the Bronze layer into the Silver layer.

    The procedure performs a full refresh of the Silver layer
    by truncating existing Silver data before each load.

Transformations include:
    - Duplicate handling
    - String trimming and standardization
    - Code-to-description mappings
    - Key standardization
    - Date validation and conversion
    - Data consistency corrections
    - Business rule enforcement

Data Flow:
    Bronze Layer
        ↓
    Cleaning & Transformation
        ↓
    Silver Layer

Execution:
    EXEC silver.load_silver;

WARNING:
    TRUNCATE TABLE permanently removes existing Silver data
    before loading the latest transformed data.

    Do NOT run this procedure against production tables
    without implementing appropriate recovery and
    transaction-management strategies.

Note:
    This procedure is designed for the current project
    using a full-refresh loading strategy.
=============================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    BEGIN TRY

        -- =====================================================
        -- Initialize Execution Variables
        -- =====================================================

        DECLARE @ProcedureStartTime DATETIME2 = SYSDATETIME();
        DECLARE @TableStartTime DATETIME2;
        DECLARE @TableEndTime DATETIME2;
        DECLARE @RowCount INT;

        PRINT '=========================================================';
        PRINT 'Starting Silver Layer Load';
        PRINT 'Start Time: '
            + CONVERT(VARCHAR(30), @ProcedureStartTime, 121);
        PRINT '=========================================================';


        -- =====================================================
        -- CRM: Customer
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Loading: silver.crm_cust_info';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'M'
                    THEN 'Married'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S'
                    THEN 'Single'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'M'
                    THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F'
                    THEN 'Female'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT
                *,
                RANK() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
              AND cst_marital_status IS NOT NULL
        ) t
        WHERE flag_last = 1;

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: silver.crm_cust_info';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @TableStartTime,
                    @TableEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- CRM: Product
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Loading: silver.crm_prd_info';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            TRIM(prd_nm) AS prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M'
                    THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R'
                    THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S'
                    THEN 'other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T'
                    THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            prd_start_dt,
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: silver.crm_prd_info';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @TableStartTime,
                    @TableEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- CRM: Sales
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Loading: silver.crm_sales_details';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            CASE
                WHEN sls_order_dt <= 0
                  OR LEN(sls_order_dt) <> 8
                    THEN NULL
                ELSE TRY_CONVERT(
                    DATE,
                    CAST(sls_order_dt AS VARCHAR(8)),
                    112
                )
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt <= 0
                  OR LEN(sls_ship_dt) <> 8
                    THEN NULL
                ELSE TRY_CONVERT(
                    DATE,
                    CAST(sls_ship_dt AS VARCHAR(8)),
                    112
                )
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt <= 0
                  OR LEN(sls_due_dt) <> 8
                    THEN NULL
                ELSE TRY_CONVERT(
                    DATE,
                    CAST(sls_due_dt AS VARCHAR(8)),
                    112
                )
            END AS sls_due_dt,

            CASE
                WHEN sls_sales IS NULL
                  OR sls_sales <= 0
                  OR sls_sales <> sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            CASE
                WHEN sls_price < 0
                    THEN ABS(sls_price)
                WHEN sls_price = 0
                  OR sls_price IS NULL
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_details;

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: silver.crm_sales_details';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @TableStartTime,
                    @TableEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- ERP: Customer
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Loading: silver.erp_cust_az12';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            CASE
                WHEN bdate > GETDATE()
                    THEN NULL
                ELSE bdate
            END AS bdate,

            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                    THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: silver.erp_cust_az12';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @TableStartTime,
                    @TableEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- ERP: Location
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Loading: silver.erp_loc_a101';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,

            CASE
                WHEN TRIM(cntry) = 'DE'
                    THEN 'Germany'
                WHEN UPPER(TRIM(cntry)) IN ('US', 'USA')
                    THEN 'United States'
                WHEN TRIM(cntry) = ''
                  OR cntry IS NULL
                    THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: silver.erp_loc_a101';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @TableStartTime,
                    @TableEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- ERP: Product Category
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Loading: silver.erp_px_cat_g1v2';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: silver.erp_px_cat_g1v2';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @TableStartTime,
                    @TableEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- Completion
        -- =====================================================

        PRINT '';
        PRINT '=========================================================';
        PRINT 'Silver Layer Load Completed Successfully';
        PRINT 'End Time: '
            + CONVERT(VARCHAR(30), SYSDATETIME(), 121);
        PRINT 'Total Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @ProcedureStartTime,
                    SYSDATETIME()
                ) AS VARCHAR(20)
              )
            + ' ms';
        PRINT '=========================================================';

    END TRY


    BEGIN CATCH

        -- =====================================================
        -- Error Handling
        -- =====================================================

        PRINT '';
        PRINT '=========================================================';
        PRINT 'ERROR: Silver Layer Load Failed';
        PRINT '=========================================================';
        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS VARCHAR(20));
        PRINT 'Error Message: '
            + ERROR_MESSAGE();
        PRINT 'Error Line: '
            + CAST(ERROR_LINE() AS VARCHAR(20));
        PRINT 'Error Procedure: '
            + ISNULL(ERROR_PROCEDURE(), 'silver.load_silver');
        PRINT 'Error Time: '
            + CONVERT(VARCHAR(30), SYSDATETIME(), 121);
        PRINT '=========================================================';

        THROW;

    END CATCH

END;
GO
