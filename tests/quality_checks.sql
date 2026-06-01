-- ============================================================
-- DATA QUALITY CHECKS
-- Project  : SQL Data Warehouse & Analytics
-- Author   : Disha Jain
-- Purpose  : Validate data integrity across Bronze, Silver, Gold layers
-- Run this : After executing all Bronze → Silver → Gold scripts
-- ============================================================
 
 
-- ============================================================
-- BRONZE LAYER CHECKS
-- Goal: Confirm raw data loaded correctly from CSV files
-- ============================================================
 
-- 1. Row count sanity check — Bronze tables should not be empty
SELECT 'bronze.crm_cust_info'   AS table_name, COUNT(*) AS row_count FROM bronze.crm_cust_info
UNION ALL
SELECT 'bronze.crm_prd_info',                  COUNT(*)               FROM bronze.crm_prd_info
UNION ALL
SELECT 'bronze.crm_sales_details',             COUNT(*)               FROM bronze.crm_sales_details
UNION ALL
SELECT 'bronze.erp_cust_az12',                 COUNT(*)               FROM bronze.erp_cust_az12
UNION ALL
SELECT 'bronze.erp_loc_a101',                  COUNT(*)               FROM bronze.erp_loc_a101
UNION ALL
SELECT 'bronze.erp_px_cat_g1v2',               COUNT(*)               FROM bronze.erp_px_cat_g1v2;
 
 
-- ============================================================
-- SILVER LAYER CHECKS
-- Goal: Confirm cleansing and transformation worked correctly
-- ============================================================
 
-- 2. Check for NULL customer IDs — should return 0
SELECT COUNT(*) AS null_customer_ids
FROM silver.crm_cust_info
WHERE cst_id IS NULL;
 
-- 3. Check for duplicate customer IDs — each customer should appear once
SELECT cst_id, COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;
 
-- 4. Check for NULLs in critical customer fields
SELECT
    SUM(CASE WHEN cst_firstname IS NULL THEN 1 ELSE 0 END) AS null_firstname,
    SUM(CASE WHEN cst_lastname  IS NULL THEN 1 ELSE 0 END) AS null_lastname,
    SUM(CASE WHEN cst_email     IS NULL THEN 1 ELSE 0 END) AS null_email
FROM silver.crm_cust_info;
 
-- 5. Check for invalid or future order dates
SELECT COUNT(*) AS invalid_order_dates
FROM silver.crm_sales_details
WHERE order_date > GETDATE()
   OR order_date IS NULL;
 
-- 6. Check that ship_date is always after order_date
SELECT COUNT(*) AS ship_before_order
FROM silver.crm_sales_details
WHERE ship_date < order_date;
 
-- 7. Check for negative or zero sales amounts (data anomaly)
SELECT COUNT(*) AS invalid_sales_amounts
FROM silver.crm_sales_details
WHERE sales_amount <= 0;
 
-- 8. Check for products with no category assigned
SELECT COUNT(*) AS uncategorized_products
FROM silver.crm_prd_info
WHERE cat_id IS NULL;
 
 
-- ============================================================
-- GOLD LAYER CHECKS
-- Goal: Confirm star schema integrity before analytics queries
-- ============================================================
 
-- 9. Check for duplicate surrogate keys in dimension tables
SELECT product_key, COUNT(*) AS cnt
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;
 
SELECT customer_key, COUNT(*) AS cnt
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;
 
-- 10. Referential integrity: all sales should have a matching customer
SELECT COUNT(*) AS orphaned_sales_customers
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;
 
-- 11. Referential integrity: all sales should have a matching product
SELECT COUNT(*) AS orphaned_sales_products
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
WHERE p.product_key IS NULL;
 
-- 12. Check date range validity — confirm reasonable order date range
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    COUNT(DISTINCT YEAR(order_date)) AS years_covered
FROM gold.fact_sales;
 
-- 13. Revenue sanity check — total revenue should be a positive number
SELECT
    SUM(sales_amount)   AS total_revenue,
    AVG(sales_amount)   AS avg_order_value,
    COUNT(*)            AS total_transactions
FROM gold.fact_sales;
 
-- 14. Confirm all Gold dimension tables have data
SELECT 'gold.dim_customers' AS table_name, COUNT(*) AS row_count FROM gold.dim_customers
UNION ALL
SELECT 'gold.dim_products',                COUNT(*)               FROM gold.dim_products
UNION ALL
SELECT 'gold.fact_sales',                  COUNT(*)               FROM gold.fact_sales;
 
