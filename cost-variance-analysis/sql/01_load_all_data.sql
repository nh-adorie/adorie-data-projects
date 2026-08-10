CREATE DATABASE IF NOT EXISTS cost_variance_analysis;
USE cost_variance_analysis;

SET GLOBAL local_infile = 1;

-- ============================================================

CREATE TABLE IF NOT EXISTS model_master (
    model                   VARCHAR(20),
    category                VARCHAR(10),
    market                  VARCHAR(50),
    standard_cost_domestic  DECIMAL(18,4),
    standard_cost_import    DECIMAL(18,4),
    exf                     DECIMAL(18,4),
    import_usd_value        DECIMAL(18,4),
    import_jpy_value        DECIMAL(18,4)
);

CREATE TABLE IF NOT EXISTS fx_rate (
    version   VARCHAR(20),
    month     VARCHAR(20),
    currency  VARCHAR(10),
    to_vnd    DECIMAL(18,4)
);

CREATE TABLE IF NOT EXISTS quantity (
    version   VARCHAR(20),
    model     VARCHAR(20),
    quantity  INT,
    month     VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS bom_data (
    version           VARCHAR(20),
    month             VARCHAR(20),
    model             VARCHAR(20),
    part_code         VARCHAR(50),
    part_name         VARCHAR(255),
    source            VARCHAR(20),
    lm_value          DECIMAL(18,4),
    tm_value          DECIMAL(18,4),
    gap               DECIMAL(18,4),
    cu_cr             VARCHAR(10),
    reason            VARCHAR(255),
    reason_category   VARCHAR(100)
);

-- ============================================================
TRUNCATE TABLE model_master;
TRUNCATE TABLE fx_rate;
TRUNCATE TABLE quantity;
TRUNCATE TABLE bom_data;

-- ============================================================

LOAD DATA LOCAL INFILE "C:\Users\Admin\Downloads\projects\cost-variance-analysis\data\model_master.csv"
INTO TABLE model_master
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(model, category, market, standard_cost_domestic, standard_cost_import,
 exf, import_usd_value, import_jpy_value);

LOAD DATA LOCAL INFILE "C:\Users\Admin\Downloads\projects\cost-variance-analysis\data\fx_rate.csv"
INTO TABLE fx_rate
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(version, month, currency, to_vnd);

LOAD DATA LOCAL INFILE "C:\Users\Admin\Downloads\projects\cost-variance-analysis\data\quantity.csv"
INTO TABLE quantity
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(version, model, quantity, month);

LOAD DATA LOCAL INFILE "C:\Users\Admin\Downloads\projects\cost-variance-analysis\data\bom_data.csv"
INTO TABLE bom_data
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(version, month, model, part_code, part_name, source,
 lm_value, tm_value, gap, cu_cr, reason, reason_category);

-- ============================================================

SELECT 'model_master' AS tbl, COUNT(*) AS rows_count FROM model_master
UNION ALL SELECT 'fx_rate', COUNT(*) FROM fx_rate
UNION ALL SELECT 'quantity', COUNT(*) FROM quantity
UNION ALL SELECT 'bom_data', COUNT(*) FROM bom_data;