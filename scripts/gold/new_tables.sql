TRUNCATE TABLE gold.daily_store_sales;
INSERT INTO gold.daily_store_sales
(
    sales_date,
    store_id,
    net_sales,
    units_sold,
    transactions,
    visitors,
    conversion_rate,
    load_timestamp
)
SELECT
    s.sales_date,
    p.store_id,
    SUM(s.net_amount)                    AS net_sales,
    SUM(s.quantity)                      AS units_sold,
    COUNT(DISTINCT s.transaction_id)     AS transactions,
    ISNULL(t.visitor_count, 0)           AS visitors,
    CASE 
        WHEN ISNULL(t.visitor_count, 0) = 0 THEN 0
        ELSE CAST(COUNT(DISTINCT s.transaction_id) AS FLOAT) 
             / CAST(t.visitor_count AS FLOAT)
    END                                  AS conversion_rate,
    SYSDATETIME()                        AS load_timestamp
FROM silver.fact_sales_net s
JOIN silver.dim_products p
    ON s.product_id = p.product_id
LEFT JOIN silver.fact_store_traffic t
    ON  s.sales_date = t.traffic_date
    AND p.store_id   = t.store_id
GROUP BY
    s.sales_date,
    p.store_id,
    t.visitor_count;
    --------------------------------------

DROP TABLE IF EXISTS gold.monthly_store_summary;
GO
CREATE TABLE gold.monthly_store_summary
(
    year_month        CHAR(7),   -- e.g. 2024-01
    store_id          NVARCHAR(20),
    net_sales         DECIMAL(18,2),
    units_sold        INT,
    transactions      INT,
    visitors          INT,
    conversion_rate   DECIMAL(10,4),
    load_timestamp    DATETIME2 DEFAULT SYSDATETIME(),
    CONSTRAINT PK_monthly_store_summary 
        PRIMARY KEY (year_month, store_id)
);
TRUNCATE TABLE gold.monthly_store_summary;
INSERT INTO gold.monthly_store_summary
(
    year_month,
    store_id,
    net_sales,
    units_sold,
    transactions,
    visitors,
    conversion_rate,
    load_timestamp
)
SELECT
    FORMAT(sales_date, 'yyyy-MM')            AS year_month,
    store_id,
    SUM(net_sales)                           AS net_sales,
    SUM(units_sold)                          AS units_sold,
    SUM(transactions)                        AS transactions,
    SUM(visitors)                            AS visitors,

    CASE 
        WHEN SUM(visitors) = 0 THEN 0
        ELSE CAST(SUM(transactions) AS FLOAT) / CAST(SUM(visitors) AS FLOAT)
    END                                      AS conversion_rate,

    SYSDATETIME()                            AS load_timestamp
FROM gold.daily_store_sales
GROUP BY
    FORMAT(sales_date, 'yyyy-MM'),
    store_id;
-----------------------------------------------

DROP TABLE IF EXISTS gold.customer_rfm;
GO
CREATE TABLE gold.customer_rfm
(
    customer_id     NVARCHAR(20) PRIMARY KEY,
    recency_days    INT,           -- days since last purchase
    frequency       INT,           -- number of transactions
    monetary        DECIMAL(18,2),  -- total net spend
    last_purchase_date DATE,
    load_timestamp  DATETIME2 DEFAULT SYSDATETIME()
);
TRUNCATE TABLE gold.customer_rfm;
INSERT INTO gold.customer_rfm
(
    customer_id,
    recency_days,
    frequency,
    monetary,
    last_purchase_date,
    load_timestamp
)
SELECT
    customer_id,

    DATEDIFF(
        DAY,
        MAX(sales_date),
        (SELECT MAX(sales_date) FROM silver.fact_sales_net)
    ) AS recency_days,

    COUNT(DISTINCT transaction_id) AS frequency,

    SUM(net_amount) AS monetary,

    MAX(sales_date) AS last_purchase_date,

    SYSDATETIME() AS load_timestamp
FROM silver.fact_sales_net
GROUP BY customer_id;

