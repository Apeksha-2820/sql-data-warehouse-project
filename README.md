# 🚀 SQL Data Warehouse & Analytics Project

## 📌 Project Overview

This project demonstrates the design and implementation of a modern **SQL Server Data Warehouse** to consolidate sales data from multiple source systems and provide a reliable foundation for analytical reporting.

The project follows a **Medallion Architecture** with Bronze, Silver, and Gold layers, covering data ingestion, data cleansing, transformation, integration, and analytical modeling.

---

## 🎯 Project Objectives

- Build a centralized SQL Server Data Warehouse for sales analytics.
- Integrate data from **CRM and ERP source systems**.
- Implement data cleansing and transformation processes.
- Develop a business-friendly analytical data model.
- Enable analysis of customer behavior, product performance, and sales trends.
- Apply Data Engineering best practices for data quality, validation, and documentation.

---

## 📂 Data Sources

The project uses CSV files from two source systems:

### CRM
- Customer information
- Product information
- Sales transaction details

### ERP
- Customer information
- Customer location information
- Product category information

---

## 🏗️ Data Architecture

The warehouse follows a **Medallion Architecture**:

```text
CRM ───────┐
           │
           ▼
        🟤 BRONZE
      Raw Source Data
           │
ERP ───────┘
           │
           ▼
        ⚪ SILVER
   Cleaned & Integrated
           │
           ▼
        🟡 GOLD
   Business-Ready Model
           │
           ▼
       📊 Analytics
