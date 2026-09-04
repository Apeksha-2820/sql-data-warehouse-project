/*
=============================================================
Load Raw Data into Bronze Layer
=============================================================
Purpose:
    Clears existing Bronze data and loads the latest raw
    data from CRM and ERP CSV source files.

    Includes:
        - TRY...CATCH error handling
        - Progress/debugging messages
        - Start and end timestamps
        - Table-level load execution time
        - Total procedure execution time
        - Row count validation

WARNING:
    TRUNCATE TABLE permanently removes all existing data
    from the Bronze tables before loading new data.

    Do NOT run this procedure against production tables.

Note:
    This procedure performs a full refresh of the Bronze layer.
=============================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
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
        PRINT 'Starting Bronze Layer Data Load';
        PRINT 'Start Time: '
            + CONVERT(VARCHAR(30), @ProcedureStartTime, 121);
        PRINT '=========================================================';


        -- =====================================================
        -- CRM: Customer
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Starting Load: bronze.crm_cust_info';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Truncating bronze.crm_cust_info...';

        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT 'Loading data from cust_info.csv...';

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\apeks\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: bronze.crm_cust_info';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(DATEDIFF(MILLISECOND, @TableStartTime, @TableEndTime) AS VARCHAR(20))
            + ' ms';


        -- =====================================================
        -- CRM: Product
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Starting Load: bronze.crm_prd_info';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Truncating bronze.crm_prd_info...';

        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT 'Loading data from prd_info.csv...';

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\apeks\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: bronze.crm_prd_info';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(DATEDIFF(MILLISECOND, @TableStartTime, @TableEndTime) AS VARCHAR(20))
            + ' ms';


        -- =====================================================
        -- CRM: Sales
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Starting Load: bronze.crm_sales_details';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Truncating bronze.crm_sales_details...';

        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT 'Loading data from sales_details.csv...';

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\apeks\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: bronze.crm_sales_details';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(DATEDIFF(MILLISECOND, @TableStartTime, @TableEndTime) AS VARCHAR(20))
            + ' ms';


        -- =====================================================
        -- ERP: Customer
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Starting Load: bronze.erp_cust_az12';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Truncating bronze.erp_cust_az12...';

        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT 'Loading data from CUST_AZ12.csv...';

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\apeks\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: bronze.erp_cust_az12';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(DATEDIFF(MILLISECOND, @TableStartTime, @TableEndTime) AS VARCHAR(20))
            + ' ms';


        -- =====================================================
        -- ERP: Location
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Starting Load: bronze.erp_loc_a101';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Truncating bronze.erp_loc_a101...';

        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT 'Loading data from LOC_A101.csv...';

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\apeks\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: bronze.erp_loc_a101';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(DATEDIFF(MILLISECOND, @TableStartTime, @TableEndTime) AS VARCHAR(20))
            + ' ms';


        -- =====================================================
        -- ERP: Product Category
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Starting Load: bronze.erp_px_cat_g1v2';
        PRINT '---------------------------------------------------------';

        SET @TableStartTime = SYSDATETIME();

        PRINT 'Truncating bronze.erp_px_cat_g1v2...';

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT 'Loading data from PX_CAT_G1V2.csv...';

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\apeks\Downloads\sql-data-warehouse-project-main\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @RowCount = @@ROWCOUNT;
        SET @TableEndTime = SYSDATETIME();

        PRINT 'Successfully loaded: bronze.erp_px_cat_g1v2';
        PRINT 'Rows Loaded: ' + CAST(@RowCount AS VARCHAR(20));
        PRINT 'Load Time: '
            + CAST(DATEDIFF(MILLISECOND, @TableStartTime, @TableEndTime) AS VARCHAR(20))
            + ' ms';


        -- =====================================================
        -- Procedure Completion
        -- =====================================================

        PRINT '';
        PRINT '=========================================================';
        PRINT 'Bronze Layer Data Load Completed Successfully';
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
        PRINT 'ERROR: Bronze Layer Data Load Failed';
        PRINT '=========================================================';
        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS VARCHAR(20));
        PRINT 'Error Message: '
            + ERROR_MESSAGE();
        PRINT 'Error Line: '
            + CAST(ERROR_LINE() AS VARCHAR(20));
        PRINT 'Error Procedure: '
            + ISNULL(ERROR_PROCEDURE(), 'bronze.load_bronze');
        PRINT 'Error Time: '
            + CONVERT(VARCHAR(30), SYSDATETIME(), 121);
        PRINT '=========================================================';

        -- Re-raise the error
        THROW;

    END CATCH

END;
GO
