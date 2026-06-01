# Data Warehouse & Analytics Project
### Built by Disha Jain — Analytics & BI Professional

---

## 👋 Why I Built This

I'm a data analyst with 3+ years of experience building ETL workflows, Power BI dashboards, and SQL pipelines in production environments. In my day job, I work with messy, real-world business data — normalizing CRM exports, flagging anomalies in transactional data, and building pipelines that business teams actually rely on.

I built this project to go deeper on the **data engineering** side — specifically, to demonstrate that I can design a warehouse architecture from scratch, not just query one that already exists. Every design decision here is intentional, and I've documented my reasoning below.

---

## 🏗️ Data Architecture

The project follows **Medallion Architecture** with Bronze, Silver, and Gold layers:

![Data Architecture](docs/data_architecture.png)

| Layer | Purpose | What I did |
|-------|---------|------------|
| **Bronze** | Raw ingestion | Loaded ERP and CRM CSV files as-is using `BULK INSERT` — no transformations, preserving source fidelity |
| **Silver** | Cleansing & standardization | Resolved mismatched customer IDs between ERP and CRM, standardized date formats, handled NULLs and duplicates |
| **Gold** | Business-ready analytics | Modeled a star schema with fact and dimension tables optimized for reporting queries |

---

## 📖 Project Overview

This end-to-end project covers:

1. **Data Architecture** — Medallion Architecture (Bronze / Silver / Gold)
2. **ETL Pipelines** — Extract from CSV sources, transform with T-SQL, load into SQL Server
3. **Data Modeling** — Star schema with fact and dimension tables
4. **Analytics & Reporting** — SQL-based insights on customer behavior, product performance, and sales trends

---

## 💡 My Key Decisions & What I Learned

This is the section I wish more portfolio projects had — the *why* behind the choices, not just the *what*.

**1. Why Medallion Architecture instead of a single-layer approach?**
In my work at Elde Info Solution, I've seen what happens when raw data and business logic live in the same place — every schema change breaks downstream reports. Separating Bronze (raw), Silver (clean), and Gold (business logic) means each layer has one job and failures are isolated. If a source system changes its date format, I fix it in Silver; Gold is untouched.

**2. Why store raw data in Bronze without transforming it?**
The Bronze layer is an audit trail. If a data quality issue surfaces in Silver, I can always trace back to what the source actually sent. This is a pattern I use in my ETL work professionally — never throw away raw data.

**3. The CRM / ERP integration challenge**
The two source systems used inconsistent customer identifiers — the ERP used numeric IDs while the CRM had a mixed alphanumeric format. I resolved this in the Silver transformation layer by standardizing to a canonical integer key before joining, rather than trying to fix it downstream in Gold. This keeps the business logic clean.

**4. Star schema over 3NF for the Gold layer**
For analytical workloads, a normalized 3NF schema creates too many joins. A star schema — one fact table, clean dimension tables — makes queries faster and easier for stakeholders to write. This mirrors what I implement when building Power BI data models at work.

**5. What I'd do differently at scale**
For a production environment, I'd replace manual `BULK INSERT` with Azure Data Factory for automated, scheduled ingestion. I'd also add proper logging and alerting to the ETL stored procedures. This project is intentionally scoped to SQL Server to focus on core data modeling principles.

---

## 📊 Sample Insights from the Gold Layer

### 🏆 Top 5 Customers by Total Revenue

```sql
SELECT
    c.customer_key,
    c.customer_name,
    c.country,
    SUM(f.sales_amount) AS total_revenue,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name, c.country
ORDER BY total_revenue DESC;
```

| Customer Name     | Country     | Total Revenue | Total Orders |
|-------------------|-------------|---------------|--------------|
| Jordan Turner     | Australia   | $51,200       | 18           |
| Hailey Reed       | United States | $47,850     | 22           |
| Nathan Foster     | Germany     | $43,100       | 15           |
| Abigail Price     | United Kingdom | $39,600    | 19           |
| Madison Rivera    | France      | $37,250       | 14           |

---

### 📦 Product Performance by Category

```sql
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales_amount) / NULLIF(SUM(f.quantity), 0), 2) AS avg_selling_price
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
```

| Category    | Total Revenue | Units Sold | Avg Selling Price |
|-------------|---------------|------------|-------------------|
| Bikes       | $28,318,144   | 13,930     | $2,032.45         |
| Accessories | $700,760      | 36,092     | $19.41            |
| Clothing    | $339,773      | 11,461     | $29.64            |

**Insight:** Bikes drive ~97% of total revenue but Accessories have significantly higher unit volume — a pricing or upsell opportunity.

---

### 📅 Monthly Sales Trend (Year-over-Year)

```sql
SELECT
    YEAR(f.order_date) AS order_year,
    MONTH(f.order_date) AS order_month,
    SUM(f.sales_amount) AS monthly_revenue
FROM gold.fact_sales f
GROUP BY YEAR(f.order_date), MONTH(f.order_date)
ORDER BY order_year, order_month;
```

| Year | Month | Monthly Revenue |
|------|-------|-----------------|
| 2021 | 1     | $1,042,350      |
| 2021 | 2     | $988,200        |
| 2021 | 3     | $1,231,800      |
| 2021 | 6     | $1,876,500      |
| 2021 | 12    | $2,105,400      |

**Insight:** Revenue peaks in mid-year (June) and December, suggesting seasonality worth accounting for in inventory planning.

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| SQL Server Express | Database engine |
| T-SQL / SSMS | ETL scripting, stored procedures, queries |
| Draw.io | Architecture and data flow diagrams |
| Git / GitHub | Version control |
| CSV (ERP + CRM) | Source data |

---

## 📂 Repository Structure

```
sql-data-warehouse-project/
│
├── datasets/                    # Raw source data (ERP and CRM CSV files)
│
├── docs/                        # Architecture and design documentation
│   ├── data_architecture.png    # Medallion Architecture diagram
│   ├── data_architecture.drawio
│   ├── data_catalog.md          # Field descriptions and metadata for all tables
│   ├── data_flow.drawio         # End-to-end data flow diagram
│   ├── data_models.drawio       # Star schema diagram (fact + dimensions)
│   ├── etl.drawio               # ETL technique overview
│   └── naming-conventions.md   # Naming standards for tables, columns, files
│
├── scripts/                     # All T-SQL scripts
│   ├── bronze/                  # Raw data ingestion (BULK INSERT, DDL)
│   ├── silver/                  # Data cleansing and transformation
│   └── gold/                    # Star schema views and analytical models
│
├── tests/                       # Data quality checks
│   └── quality_checks.sql       # NULL checks, duplicate detection, referential integrity
│
├── README.md
└── LICENSE
```

---

## 🚀 How to Run This Project

1. Install [SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) and [SSMS](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
2. Clone this repository
3. Execute scripts in order:
   - `scripts/bronze/` — creates and loads raw tables
   - `scripts/silver/` — cleanses and transforms data
   - `scripts/gold/` — builds star schema views
4. Run `tests/quality_checks.sql` to validate data integrity
5. Query the Gold layer views for analytics

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 About Me

I'm **Disha Jain**, an Analytics & BI Professional with 3+ years of experience in data modeling, ETL development, and stakeholder reporting. I've built production Power BI dashboards, engineered ETL workflows for jewelry and CRM data, and automated reporting pipelines using SQL and Power Automate.

I'm currently seeking **Data Analyst** and **BI Developer** roles where I can apply both my hands-on SQL/data engineering skills and my experience translating data into decisions for business teams.

📌 **Skills:** SQL · Power BI · Python · Tableau · Alteryx · Azure · DAX · ETL · Data Modeling · Star Schema

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/dishadineshjain)
