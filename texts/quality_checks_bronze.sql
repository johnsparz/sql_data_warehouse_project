
/*
--------------------------------------
Global Row Count Snapshot
Starting with a high-level inventory
--------------------------------------
*/
SELECT 'bronze.customers' AS table_name, COUNT(*) AS row_count FROM bronze.customers
UNION ALL
SELECT 'bronze.stores', COUNT(*) FROM bronze.stores
UNION ALL
SELECT 'bronze.products', COUNT(*) FROM bronze.products
UNION ALL
SELECT 'bronze.transactions_dirty', COUNT(*) FROM bronze.transactions_dirty
UNION ALL
SELECT 'bronze.returns', COUNT(*) FROM bronze.returns
UNION ALL
SELECT 'bronze.inventory_snapshot', COUNT(*) FROM bronze.inventory_snapshot
UNION ALL
SELECT 'bronze.promotions', COUNT(*) FROM bronze.promotions
UNION ALL
SELECT 'bronze.store_foot_traffic', COUNT(*) FROM bronze.store_foot_traffic
UNION ALL
SELECT 'bronze.customer_pii', COUNT(*) FROM bronze.customer_pii;

/*
--------------------------------------
Column-Level Null Profiling
Table: bronze.transactions_dirty
Result: 12 'null_payment_method'
--------------------------------------
*/
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN payment_method IS NULL THEN 1 ELSE 0 END) AS null_payment_method,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS null_transaction_date
FROM bronze.transactions_dirty;

/*
--------------------------------------
Column-Level Null Profiling
bronze.customer_pii
Result: 126 'missing email'
--------------------------------------
*/
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS missing_email
FROM bronze.customer_pii;

/*
--------------------------------------
Primary Key Uniqueness Checks (Soft)
Transactions
Customers
Result: No duplicates
--------------------------------------
*/
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_id) AS distinct_transaction_ids
FROM bronze.transactions_dirty;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM bronze.customers;

/*
--------------------------------------
Referential Integrity (Reality Check)
Orphan Products in Transactions
Orphan Customers
Result: 15 'orphan_product_rows'
Result: 1 'orphan_customer'
--------------------------------------
*/
SELECT COUNT(*) AS orphan_product_rows
FROM bronze.transactions_dirty t
LEFT JOIN bronze.products p
    ON t.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS orphan_customers
FROM bronze.transactions_dirty t
LEFT JOIN bronze.customers c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/*
--------------------------------------
Range & Validity Checks
Negative Quantities
Result: 0
--------------------------------------
*/
SELECT COUNT(*) AS negative_quantity_rows
FROM bronze.transactions_dirty
WHERE quantity < 0;

/*
--------------------------------------
Impossible Discounts
Result: 0
--------------------------------------
*/
SELECT COUNT(*) AS invalid_discounts
FROM bronze.transactions_dirty
WHERE discount_pct < 0 OR discount_pct > 100;

/*
--------------------------------------
Refund > Transaction Amount (Cross-table)
Result: 54
--------------------------------------
*/
SELECT COUNT(*) AS excessive_refunds
FROM bronze.returns r
JOIN bronze.transactions_dirty t
    ON r.transaction_id = t.transaction_id
WHERE r.refund_amount > t.total_amount;

/*
--------------------------------------
Date Coverage Analysis
Transactions Date Range
Foot Traffic Date Coverage
Result: Range 
Result: No missing period nor partial ingestion
        Foot traffic data is complete and continuous
--------------------------------------
*/
SELECT
    MIN(transaction_date) AS min_date,
    MAX(transaction_date) AS max_date
FROM bronze.transactions_dirty;

SELECT
    MIN([date]) AS start_date,
    MAX([date]) AS end_date,
    COUNT(DISTINCT [date]) AS active_days
FROM bronze.store_foot_traffic;

/*
--------------------------------------
Category Cardinality & Standardization Check
Product Categories
Result: Misspellings: 0
        Overlapping values: 0
        Case inconsistencies: 0
--------------------------------------
*/
SELECT category, COUNT(*) AS product_count
FROM bronze.products
GROUP BY category
ORDER BY product_count DESC;






