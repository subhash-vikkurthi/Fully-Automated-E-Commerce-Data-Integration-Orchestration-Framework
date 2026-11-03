# 🚀 Fully Automated E-Commerce Data Engineering Framework

### An End-to-End Automated Data Engineering Solution Using Snowflake & AWS

## 📌 Project Overview

This project implements a **Fully Automated E-Commerce Data Engineering Framework** using Snowflake and AWS to automate the end-to-end data ingestion, transformation, processing, and monitoring lifecycle.

The framework follows the **Medallion Architecture (Bronze → Silver → Gold)** to organize data into structured layers, ensuring data quality, consistency, and reliability.

The pipeline leverages Snowflake Streams for Change Data Capture (CDC), Tasks for automated orchestration, and SQL Stored Procedures for reusable transformation logic.

Additionally, an automated auditing and notification mechanism tracks pipeline execution, records processing metrics, and sends email notifications for successful and failed executions.

**The entire pipeline operates without manual intervention during successful executions. Manual intervention is only required when an error needs troubleshooting or recovery.**

---

## 🎯 Project Objectives

- Build an end-to-end automated E-Commerce data engineering pipeline.
- Automate data ingestion from AWS S3 into Snowflake.
- Implement CDC to capture and process incremental data changes.
- Develop automated data transformations using SQL Stored Procedures.
- Implement Medallion Architecture for structured data processing.
- Automate pipeline execution using Snowflake Tasks and task dependencies.
- Maintain historical records using Slowly Changing Dimension Type 2 (SCD Type 2).
- Implement centralized audit logging and execution monitoring.
- Configure automated email notifications for successful and failed pipeline executions.
- Minimize manual intervention through automated orchestration.

---

## 🏗️ System Architecture

The project follows a cloud-based architecture integrating AWS S3 and Snowflake.

### Architecture Flow

```text
             E-COMMERCE DATA
                    |
                    ▼
              AWS S3 BUCKET
                    |
                    ▼
          SNOWFLAKE DATA INGESTION
                    |
                    ▼
             BRONZE LAYER
          (Raw Data Storage)
                    |
                    ▼
          CHANGE DATA CAPTURE
           (Snowflake Streams)
                    |
                    ▼
             SILVER LAYER
       (Cleansing & Transformation)
                    |
                    ▼
          AUTOMATED ORCHESTRATION
             (Snowflake Tasks)
                    |
                    ▼
              GOLD LAYER
         (Business-Ready Data)
                    |
                    ▼
           POWER BI DASHBOARDS
                    |
                    ▼
            BUSINESS INSIGHTS


       AUTOMATED MONITORING SYSTEM
                    |
          ┌─────────┴─────────┐
          ▼                   ▼
      AUDIT LOGS         EMAIL ALERTS
                      (SUCCESS / FAILURE)
```

---

## ⚙️ Technology Stack

| Technology              | Purpose                                      |
| ----------------------- | -------------------------------------------- |
| Snowflake               | Cloud Data Warehouse                         |
| AWS S3                  | Cloud Object Storage and Data Ingestion      |
| SQL                     | Data Transformation and Processing           |
| Snowflake Streams       | Change Data Capture (CDC)                    |
| Snowflake Tasks         | Automated Scheduling and Orchestration       |
| SQL Stored Procedures   | Reusable Transformation and Processing Logic |
| Snowflake Notifications | Success and Failure Email Notifications      |
| Power BI                | Data Visualization and Reporting             |
| Python                  | Supporting Data Engineering Operations       |

---

## 🥉 1. Bronze Layer – Raw Data Ingestion

The Bronze Layer serves as the initial storage layer for incoming E-Commerce data.

**Implementation:**

- Store incoming source files in AWS S3.
- Connect AWS S3 with Snowflake using the required cloud integration and external stage configuration.
- Load raw data into Snowflake using the `COPY INTO` command.
- Maintain source data for subsequent processing.
- Capture changes using the configured CDC mechanism.

**Key Focus:** Reliable ingestion and preservation of raw source data.

---

## 🥈 2. Silver Layer – Data Cleansing and Transformation

The Silver Layer converts raw data into clean, consistent, and structured datasets.

**Implementation:**

- Identify and handle NULL values.
- Standardize inconsistent data values.
- Validate data attributes and business rules.
- Handle duplicate records.
- Apply SQL-based transformations.
- Use Snowflake Streams to identify incremental changes.
- Use MERGE operations to process inserts, updates, and applicable deletes.

**Key Focus:** Maintaining data quality and processing incremental changes efficiently.

---

## 🥇 3. Gold Layer – Business-Ready Data

The Gold Layer contains structured datasets designed for analytical and reporting requirements.

**Implementation:**

- Design fact and dimension tables.
- Implement Slowly Changing Dimension Type 2 (SCD Type 2).
- Maintain historical customer and dimensional changes.
- Track current and historical records using effective dates and current-record indicators.
- Create analytical views for reporting.
- Prepare business-ready datasets for Power BI.

**Key Focus:** Delivering reliable and analytics-ready data while preserving historical changes.

---

## 🔄 4. Change Data Capture (CDC)

Snowflake Streams are used to capture changes occurring in source tables.

**Implementation:**

- Create Streams on the required Snowflake tables.
- Detect new inserts, updates, and deletes.
- Utilize Stream metadata such as `METADATA$ACTION` and `METADATA$ISUPDATE`.
- Process incremental changes using SQL MERGE statements.
- Avoid unnecessary full-table processing.
- Trigger downstream processing based on stream availability.

**Key Focus:** Efficient incremental data processing instead of repeatedly processing entire datasets.

---

## ⚡ 5. Automated Orchestration Using Snowflake Tasks

Snowflake Tasks coordinate the execution of different pipeline operations.

**Implementation:**

- Create parent and child tasks to organize execution dependencies.
- Use conditional task execution with `SYSTEM$STREAM_HAS_DATA()`.
- Execute SQL Stored Procedures through Tasks.
- Automate downstream processing based on upstream task dependencies.
- Configure task failure handling and retry mechanisms.
- Use task history to monitor execution status.

**Key Focus:** Automating the execution of the entire data processing workflow without requiring manual execution of individual SQL statements.

---

## 📋 6. Automated Audit Logging

An auditing mechanism is implemented to maintain execution-level details of pipeline operations.

**Audit information includes:**

- Table Name
- File Name
- Action Type
- Rows Read
- Rows Inserted
- Rows Updated
- Execution Status
- Start Time
- End Time
- Initiated By
- Error Message

**Key Focus:**

- Track pipeline execution.
- Maintain processing history.
- Record successful and failed operations.
- Improve troubleshooting and operational visibility.

---

## 📧 7. Automated Email Notifications

An automated notification mechanism is implemented to provide execution updates.

**Notification scenarios:**

**Successful Execution:**

- Notify when the configured pipeline operation completes successfully.
- Include relevant execution details.

**Failed Execution:**

- Capture failure information.
- Record error details in the audit mechanism.
- Send failure notifications to the configured recipient.

**Key Focus:** Improving pipeline monitoring and reducing the need for continuous manual supervision.

---

## 📊 8. Data Visualization Using Power BI

The Gold Layer datasets are connected to Power BI for analytical reporting.

**Implementation:**

- Connect Power BI to Snowflake.
- Consume business-ready datasets.
- Develop analytical dashboards.
- Present meaningful business insights.

**Key Focus:** Transforming processed data into actionable business information.

---

## 🔁 End-to-End Execution Workflow

1. Source E-Commerce data is placed in AWS S3.
2. Data is ingested into the Snowflake Bronze Layer.
3. Incremental changes are identified through Snowflake Streams.
4. SQL Stored Procedures process and transform the data.
5. Snowflake Tasks orchestrate the dependent processing operations.
6. Cleaned datasets are maintained in the Silver Layer.
7. Business transformations populate the Gold Layer.
8. SCD Type 2 maintains historical dimensional changes.
9. Audit mechanisms record execution details and processing metrics.
10. Email notifications communicate successful or failed executions.
11. Gold Layer datasets are consumed by Power BI.

---

## ⭐ Key Features

- **End-to-End Automation:** No manual intervention required during normal successful pipeline execution.
- **CDC-Based Processing:** Incremental data processing using Snowflake Streams.
- **Automated Orchestration:** Task-based execution and dependency management.
- **Medallion Architecture:** Structured Bronze, Silver, and Gold data layers.
- **Historical Data Tracking:** SCD Type 2 implementation.
- **Automated Auditing:** Execution tracking and processing metrics.
- **Error Handling:** Failure tracking and notification mechanisms.
- **Business Intelligence:** Power BI integration for analytical reporting.

---

## 📁 Project Structure

```text
Fully-Automated-Ecommerce-Data-Engineering/
│
├── README.md
│
├── Architecture/
│   └── project_architecture.png
│
├── SQL/
│   ├── 01_Database_Setup.sql
│   ├── 02_Stage_And_File_Format.sql
│   ├── 03_Bronze_Layer.sql
│   ├── 04_Silver_Layer.sql
│   ├── 05_Gold_Layer.sql
│   ├── 06_Streams_And_CDC.sql
│   ├── 07_Stored_Procedures.sql
│   ├── 08_Tasks_And_Orchestration.sql
│   ├── 09_Audit_Logging.sql
│   ├── 10_Email_Notifications.sql
│   └── 11_SCD_Type_2.sql
│
├── PowerBI/
   └── Ecommerce_Dashboard.pbix
```

*Note: This is a suggested repository structure. Adjust filenames and folders to match your actual implementation.*

---

## 🔐 Prerequisites

Before implementing the project, ensure you have:

- A Snowflake account with the required permissions.
- An AWS account.
- An AWS S3 bucket containing source data.
- Appropriate AWS IAM permissions.
- Snowflake storage integration and external stage configuration.
- Snowflake warehouse and database.
- Permission to create Streams, Tasks, and Stored Procedures.
- A configured email notification integration.
- Power BI Desktop for reporting.

---

## 🚀 Key Learning Outcomes

Through this project, I gained practical experience in:

- Building end-to-end cloud data engineering solutions.
- Integrating AWS S3 with Snowflake.
- Implementing incremental data processing using CDC.
- Developing reusable SQL Stored Procedures.
- Designing task-based orchestration workflows.
- Implementing SCD Type 2.
- Building auditing and monitoring mechanisms.
- Handling pipeline execution failures and notifications.
- Integrating Snowflake with Power BI.

---

## 👨‍💻 Author

**Subhash Vikkurthi**

Aspiring Data Engineer | Snowflake | AWS | SQL | Cloud Data Engineering

I'm actively seeking opportunities to start my career as a **Data Engineer**, where I can apply my technical skills, contribute to real-world data engineering projects, and continue learning.

📌 Open to Data Engineer Internships and Entry-Level Opportunities.

---

⭐ If you find this project interesting, feel free to explore the repository!
