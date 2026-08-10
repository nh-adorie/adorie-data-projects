USE cost_variance_analysis;
SHOW TABLES;

SELECT * FROM bom_data;
SELECT * FROM fx_rate;
SELECT * FROM model_master;
SELECT * FROM quantity;

-- Analyze sales difference btw forecast and actual--

-- Tạo view merge bảng model_master, quantity, fx
CREATE OR REPLACE VIEW view_sales AS
SELECT 
	qty.version, qty.model, qty.quantity, qty.month, 
    mm.exf, mm.market, 
    fx.to_vnd,
    ROUND(CASE
		WHEN market = 'VN' THEN mm.exf
		WHEN market != 'VN' THEN mm.exf * fx.to_vnd
	END, 2) AS unit_price_vnd,
    ROUND( CASE 
		WHEN market = 'VN' THEN qty.quantity * mm.exf / 1000000 
		WHEN market != 'VN' THEN qty.quantity * mm.exf * fx.to_vnd / 1000000 
    END, 2) AS total_sales_m_vnd
FROM quantity qty
LEFT JOIN model_master mm
	ON qty.model = mm.model
LEFT JOIN fx_rate fx
	ON qty.version = fx.version
    AND qty.month = fx.month
WHERE fx.currency = 'USD';

-- Từ view vừa tạo, tách thành forecast data và actual data để so sánh
CREATE OR REPLACE VIEW view_gap_sales AS
WITH forecast_data AS (
	SELECT * 
	FROM view_sales
	WHERE version = 'forecast'
),
actual_data AS(
	SELECT *
    FROM view_sales
    WHERE version = 'actual'
)
SELECT 
	fct.version, fct.month, fct.model, fct.exf, fct.quantity AS fct_quantity, fct.market, fct.to_vnd AS fct_fx, fct.total_sales_m_vnd AS fct_sales,
    act.quantity AS act_quantity, act.to_vnd AS act_fx, act.total_sales_m_vnd AS act_sales,
    act.total_sales_m_vnd - fct.total_sales_m_vnd AS gap_sales,
    act.quantity - fct.quantity AS gap_qty,
    ROUND((act.quantity - fct.quantity) * fct.unit_price_vnd / 1000000, 2) AS gap_by_qty,
    CASE
		WHEN fct.market = 'VN' THEN 0
        WHEN fct.market != 'VN' THEN ROUND((act.to_vnd - fct.to_vnd) * act.quantity * fct.exf / 1000000, 2) 
        END AS gap_by_fx
FROM forecast_data fct
JOIN actual_data act
	ON fct.model = act.model
    AND fct.month = act.month
ORDER BY fct.month, fct.model;

SELECT 
	month,
    SUM(fct_quantity) AS fct_total_qty,
    SUM(act_quantity) AS act_total_qty,
    SUM(gap_qty) AS total_gap_qty,
    SUM(fct_sales) AS fct_total_sales,
    SUM(act_sales) AS act_total_sales,
    SUM(gap_sales) AS total_gap_sales,
    SUM(gap_by_qty) AS gap_by_model_mix,
    SUM(gap_by_fx) AS gap_by_fx
FROM view_gap_sales
GROUP BY month;

-- Analyze CU, CR gap btw forecast and actual

-- Create view for CU CR per model
CREATE OR REPLACE VIEW view_cu_cr AS
WITH forecast_bom AS (
    SELECT * FROM bom_data WHERE version = 'forecast'
),
actual_bom AS (
    SELECT * FROM bom_data WHERE version = 'actual'
),
forecast_qty AS (
    SELECT * FROM quantity WHERE version = 'forecast'
),
actual_qty AS (
    SELECT * FROM quantity WHERE version = 'actual'
)
SELECT 
    fct.month, fct.model, fct.part_code, fct.part_name,
    forecast_qty.quantity AS fct_qty,
    actual_qty.quantity AS act_qty,
    fct.gap AS fct,
    act.gap AS act,
    CASE 
        WHEN NULLIF(TRIM(act.cu_cr), '') IS NOT NULL THEN act.cu_cr
        WHEN fct.cu_cr = 'cu' THEN 'cu'
        WHEN fct.cu_cr = 'cr' THEN 'cr'
    END AS cu_cr,

    act.gap - fct.gap AS gap_per_unit,
    ((act.gap * actual_qty.quantity) - (fct.gap * forecast_qty.quantity)) / 1000000 AS gap_total,
    (actual_qty.quantity - forecast_qty.quantity) * fct.gap / 1000000 AS gap_by_qty,
    (act.gap - fct.gap) * actual_qty.quantity / 1000000 AS gap_by_cu_cr_variance

FROM forecast_bom fct
JOIN actual_bom act
    ON fct.month = act.month
    AND fct.model = act.model
    AND fct.part_code = act.part_code
JOIN forecast_qty
    ON fct.month = forecast_qty.month
    AND fct.model = forecast_qty.model
JOIN actual_qty
    ON act.month = actual_qty.month
    AND act.model = actual_qty.model;

-- Summary CU, CR
SELECT 
    month,
    cu_cr,
    SUM(gap_total) AS gap_total,
    SUM(gap_by_qty) AS gap_by_qty,
    SUM(gap_by_cu_cr_variance) AS gap_by_cu_cr_variance
FROM view_cu_cr
WHERE cu_cr IS NOT NULL
GROUP BY month, cu_cr
ORDER BY month, cu_cr;

-- Create view total DMC
CREATE OR REPLACE VIEW view_dmc_monthly AS
SELECT
    version, model, month,
    SUM(tm_value) AS dmc_total,
    SUM(CASE WHEN cu_cr = 'cu' THEN gap ELSE 0 END) AS monthly_cu,
    SUM(CASE WHEN cu_cr = 'cr' THEN gap ELSE 0 END) AS monthly_cr,
    SUM(gap) AS monthly_net_gap
FROM bom_data
GROUP BY version, model, month;

SELECT
    fct.model, fct.month,
    fct.dmc_total AS dmc_forecast,
    act.dmc_total AS dmc_actual,
    act.dmc_total - fct.dmc_total AS cumulative_gap,
    SUM(act.monthly_cu) OVER (PARTITION BY act.model ORDER BY act.month) AS ytd_cu_actual,
    SUM(act.monthly_cr) OVER (PARTITION BY act.model ORDER BY act.month) AS ytd_cr_actual
FROM view_dmc_monthly fct
JOIN view_dmc_monthly act
    ON fct.model = act.model 
    AND fct.month = act.month
    AND fct.version = 'forecast' 
    AND act.version = 'actual'
ORDER BY fct.model, fct.month;

