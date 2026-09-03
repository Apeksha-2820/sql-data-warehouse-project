/*
=============================================================
Create Data Warehouse Database & Schemas
=============================================================
Purpose:
    Creates the DataWarehouse database and initializes
    the Bronze, Silver, and Gold schemas.

Note:
    Existing DataWarehouse database will be dropped and
    recreated to ensure a clean project environment.
=============================================================
Create Data Warehouse Database & Schemas
=============================================================
Purpose:
    Creates the DataWarehouse database and initializes
    the Bronze, Silver, and Gold schemas.
=============================================================
WARNING:
    This script DROPS the existing DataWarehouse database
    and ALL of its data if it already exists.
    Do NOT run this script in a production environment.
============================================================
*/

-- Drop existing DataWarehouse database if it exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

-- Switch to DataWarehouse database
USE DataWarehouse;
GO

-- Create Medallion Architecture schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
