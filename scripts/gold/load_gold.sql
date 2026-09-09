/*
=============================================================
Gold Layer - Create Analytical Views
=============================================================
Purpose:
    Creates the analytical views used by the Gold layer.

    The Gold layer provides business-ready data by integrating
    and organizing the cleaned Silver layer data into:

        1. Customer Dimension
        2. Product Dimension
        3. Sales Fact

Data Flow:
    Bronze
       ↓
    Silver
       ↓
    Gold
       ↓
    Analytics / Reporting

Gold Model:
    
    dim_customer
          │
          │ customer_key
          ▼
      fact_sales
          ▲
          │ product_key
          │
    dim_products

Design Notes:
    - Surrogate keys are generated using ROW_NUMBER().
    - Source/business keys are retained for traceability.
    - Current product records are retained in the product
      dimension; historical records are excluded.
    - Fact records are linked to dimensions using their
      business/source keys.
    - The fact view stores surrogate dimension keys for
      analytical relationships.

Execution:
    EXEC gold.create_gold_views;

Note:
    This implementation follows the current project scope
    and does not implement historical tracking.

=============================================================
*/


CREATE OR ALTER PROCEDURE gold.create_gold_views
AS
BEGIN

    BEGIN TRY

        -- =====================================================
        -- Initialize Execution Variables
        -- =====================================================

        DECLARE @ProcedureStartTime DATETIME2 = SYSDATETIME();
        DECLARE @ViewStartTime DATETIME2;
        DECLARE @ViewEndTime DATETIME2;


        PRINT '=========================================================';
        PRINT 'Starting Gold Layer View Creation';
        PRINT 'Start Time: '
            + CONVERT(VARCHAR(30), @ProcedureStartTime, 121);
        PRINT '=========================================================';


        -- =====================================================
        -- 1. Customer Dimension
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Creating/Updating: gold.dim_customer';
        PRINT '---------------------------------------------------------';

        SET @ViewStartTime = SYSDATETIME();

        EXEC sp_executesql N'
        CREATE OR ALTER VIEW gold.dim_customer
        AS

        SELECT
            ROW_NUMBER() OVER (
                ORDER BY ci.cst_id
            ) AS customer_key,

            ci.cst_id AS customer_id,

            ci.cst_key AS customer_number,

            ci.cst_firstname AS first_name,

            ci.cst_lastname AS last_name,

            la.cntry AS country,

            ci.cst_marital_status AS marital_status,

            CASE
                WHEN ci.cst_gndr <> ''n/a''
                    THEN ci.cst_gndr
                ELSE COALESCE(ca.gen, ''n/a'')
            END AS gender,

            ca.bdate AS birthdate,

            ci.cst_create_date AS create_date

        FROM silver.crm_cust_info ci

        LEFT JOIN silver.erp_cust_az12 ca
            ON ci.cst_key = ca.cid

        LEFT JOIN silver.erp_loc_a101 la
            ON ci.cst_key = la.cid;
        ';

        SET @ViewEndTime = SYSDATETIME();

        PRINT 'Successfully created/updated: gold.dim_customer';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @ViewStartTime,
                    @ViewEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- 2. Product Dimension
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Creating/Updating: gold.dim_products';
        PRINT '---------------------------------------------------------';

        SET @ViewStartTime = SYSDATETIME();

        EXEC sp_executesql N'
        CREATE OR ALTER VIEW gold.dim_products
        AS

        SELECT
            ROW_NUMBER() OVER (
                ORDER BY cp.prd_start_dt, cp.prd_key
            ) AS product_key,

            cp.prd_id AS product_id,

            cp.prd_key AS product_number,

            cp.prd_nm AS product_name,

            cp.cat_id AS category_id,

            ep.cat AS category,

            ep.subcat AS subcategory,

            ep.maintenance AS maintenance,

            cp.prd_cost AS product_cost,

            cp.prd_line AS product_line,

            cp.prd_start_dt AS start_date

        FROM silver.crm_prd_info cp

        LEFT JOIN silver.erp_px_cat_g1v2 ep
            ON cp.cat_id = ep.id

        WHERE cp.prd_end_dt IS NULL;
        ';

        SET @ViewEndTime = SYSDATETIME();

        PRINT 'Successfully created/updated: gold.dim_products';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @ViewStartTime,
                    @ViewEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- 3. Sales Fact
        -- =====================================================

        PRINT '';
        PRINT '---------------------------------------------------------';
        PRINT 'Creating/Updating: gold.fact_sales';
        PRINT '---------------------------------------------------------';

        SET @ViewStartTime = SYSDATETIME();

        EXEC sp_executesql N'
        CREATE OR ALTER VIEW gold.fact_sales
        AS

        SELECT
            sd.sls_ord_num AS order_number,

            pr.product_key,

            cu.customer_key,

            sd.sls_order_dt AS order_date,

            sd.sls_ship_dt AS shipping_date,

            sd.sls_due_dt AS due_date,

            sd.sls_sales AS sales_amount,

            sd.sls_quantity AS quantity,

            sd.sls_price AS price

        FROM silver.crm_sales_details sd

        LEFT JOIN gold.dim_products pr
            ON sd.sls_prd_key = pr.product_number

        LEFT JOIN gold.dim_customer cu
            ON sd.sls_cust_id = cu.customer_id;
        ';

        SET @ViewEndTime = SYSDATETIME();

        PRINT 'Successfully created/updated: gold.fact_sales';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @ViewStartTime,
                    @ViewEndTime
                ) AS VARCHAR(20)
              )
            + ' ms';


        -- =====================================================
        -- Completion
        -- =====================================================

        PRINT '';
        PRINT '=========================================================';
        PRINT 'Gold Layer View Creation Completed Successfully';
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
        PRINT 'ERROR: Gold Layer View Creation Failed';
        PRINT '=========================================================';
        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS VARCHAR(20));
        PRINT 'Error Message: '
            + ERROR_MESSAGE();
        PRINT 'Error Line: '
            + CAST(ERROR_LINE() AS VARCHAR(20));
        PRINT 'Error Procedure: '
            + ISNULL(ERROR_PROCEDURE(), 'gold.create_gold_views');
        PRINT 'Error Time: '
            + CONVERT(VARCHAR(30), SYSDATETIME(), 121);
        PRINT '=========================================================';

        THROW;

    END CATCH

END;
GO
