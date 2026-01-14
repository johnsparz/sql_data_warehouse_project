--1 DATA PROFILING
--Check missing quantities

SELECT COUNT(*) AS total_rows FROM warehouse_messy_data;

SELECT DISTINCT Quantity
FROM warehouse_messy_data
WHERE TRY_CAST(quantity AS INT) IS NULL
  AND quantity IS NOT NULL;

  -- 3. NORMALIZE TEXT FIELDS
UPDATE warehouse_messy_data
SET
    product_name = LOWER(LTRIM(RTRIM(product_name))),
    category     = UPPER(LTRIM(RTRIM(category))),
    warehouse    = UPPER(LTRIM(RTRIM(warehouse))),
    location     = UPPER(LTRIM(RTRIM(location))),
    supplier     = UPPER(LTRIM(RTRIM(supplier))),
    status       = UPPER(LTRIM(RTRIM(status)));

    -- 4. FIX TEXT NUMBERS
UPDATE warehouse_messy_data
SET quantity = '200'
WHERE quantity = 'two hundred';

--Verify again
SELECT DISTINCT quantity
FROM warehouse_messy_data
--WHERE TRY_CAST(quantity AS INT) IS NULL;


-- 5. DATE VALIDATION
SELECT last_restocked
FROM warehouse_messy_data
WHERE TRY_CONVERT(DATE, last_restocked, 103) IS NULL
  AND last_restocked IS NOT NULL;

  -- 6. CLEAN TABLE
CREATE TABLE warehouse_clean_data (
    product_id      INT,
    product_name    VARCHAR(50),
    category        VARCHAR(50),
    warehouse       NVARCHAR(50),
    location        NVARCHAR(50),
    quantity        NVARCHAR(50),
    price           DECIMAL(10,2),
    supplier        VARCHAR(50),
    status          VARCHAR(50),
    last_restocked  DATE
);

-- 7. INSERT CLEAN DATA
INSERT INTO warehouse_inventory_clean
SELECT
    product_id,
    product_name,
    category,
    warehouse,
    location,
    TRY_CAST(quantity AS INT),
    price,
    supplier,
    status,
    TRY_CONVERT(DATE, last_restocked, 103)
FROM staging_warehouse_raw;

-- 7. INSERT CLEAN DATA
INSERT INTO warehouse_clean_data
SELECT
    product_id,
    product_name,
    category,
    warehouse,
    location,
    quantity,
    price,
    supplier,
    status,
    last_restocked
FROM warehouse_messy_data;

-- 8. BUSINESS RULES
DELETE FROM warehouse_clean_data WHERE quantity < 0;

UPDATE warehouse_clean_data
SET status = 'OUT OF STOCK'
WHERE quantity = 0;

