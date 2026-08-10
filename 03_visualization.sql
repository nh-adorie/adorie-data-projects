CREATE OR REPLACE VIEW view_sales_gap_by_model AS
WITH forecast_data AS (
    SELECT * FROM view_sales WHERE version = 'forecast'
),
actual_data AS (
    SELECT * FROM view_sales WHERE version = 'actual'
)
SELECT 
    fct.month, fct.model, fct.market,
    fct.quantity AS fct_quantity, act.quantity AS act_quantity,
    fct.to_vnd AS fct_fx, act.to_vnd AS act_fx,
    fct.total_sales_m_vnd AS fct_sales, act.total_sales_m_vnd AS act_sales,
    act.total_sales_m_vnd - fct.total_sales_m_vnd AS gap_sales,
    ROUND((act.quantity - fct.quantity) * fct.unit_price_vnd / 1000000, 2) AS gap_by_qty,
    CASE
        WHEN fct.market = 'VN' THEN 0
        ELSE ROUND((act.to_vnd - fct.to_vnd) * fct.quantity * fct.exf / 1000000, 2)
    END AS gap_by_fx
FROM forecast_data fct
JOIN actual_data act
    ON fct.model = act.model AND fct.month = act.month;

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
    fct.cu_cr AS cu_cr,
    act.gap - fct.gap AS gap_per_unit,
    ((act.gap * actual_qty.quantity) - (fct.gap * forecast_qty.quantity)) / 1000000 AS gap_total,
    (actual_qty.quantity - forecast_qty.quantity) * fct.gap / 1000000 AS gap_by_qty,
    (act.gap - fct.gap) * actual_qty.quantity / 1000000 AS gap_by_cu_cr_variance
FROM forecast_bom fct
JOIN actual_bom act
    ON fct.month = act.month AND fct.model = act.model AND fct.part_code = act.part_code
JOIN forecast_qty
    ON fct.month = forecast_qty.month AND fct.model = forecast_qty.model
JOIN actual_qty
    ON act.month = actual_qty.month AND act.model = actual_qty.model;

CREATE OR REPLACE VIEW view_dmc_monthly AS
SELECT
    version, model, month,
    SUM(tm_value) AS dmc_total,
    SUM(CASE WHEN cu_cr = 'cu' THEN gap ELSE 0 END) AS monthly_cu,
    SUM(CASE WHEN cu_cr = 'cr' THEN gap ELSE 0 END) AS monthly_cr,
    SUM(gap) AS monthly_net_gap
FROM bom_data
GROUP BY version, model, month;

CREATE OR REPLACE VIEW view_dmc_total_by_month AS
SELECT month, version, SUM(dmc_total) AS dmc_total
FROM view_dmc_monthly
GROUP BY month, version;

CREATE OR REPLACE VIEW view_quantity_summary AS
SELECT version, month, SUM(quantity) AS total_qty
FROM quantity
GROUP BY version, month;

CREATE OR REPLACE VIEW view_sales_waterfall AS
SELECT month, 1 AS step_order, 'Sales Forecast' AS step, SUM(fct_sales) AS value
FROM view_sales_gap_by_model GROUP BY month
UNION ALL
SELECT month, 2, 'Quantity Variance', SUM(gap_by_qty)
FROM view_sales_gap_by_model GROUP BY month
UNION ALL
SELECT month, 3, 'FX Variance', SUM(gap_by_fx)
FROM view_sales_gap_by_model GROUP BY month;

CREATE OR REPLACE VIEW view_dmc_waterfall AS
SELECT month, 1 AS step_order, 'DMC Forecast' AS step, dmc_total/1000000 AS value
FROM view_dmc_total_by_month WHERE version = 'forecast'
UNION ALL
SELECT month, 2, 'CU - Variance', SUM(gap_by_cu_cr_variance)
FROM view_cu_cr WHERE cu_cr = 'cu' GROUP BY month
UNION ALL
SELECT month, 3, 'CU - Qty', SUM(gap_by_qty)
FROM view_cu_cr WHERE cu_cr = 'cu' GROUP BY month
UNION ALL
SELECT month, 4, 'CR - Variance', SUM(gap_by_cu_cr_variance)
FROM view_cu_cr WHERE cu_cr = 'cr' GROUP BY month
UNION ALL
SELECT month, 5, 'CR - Qty', SUM(gap_by_qty)
FROM view_cu_cr WHERE cu_cr = 'cr' GROUP BY month;

CREATE OR REPLACE VIEW view_bom_drilldown AS
SELECT
    fct.month, fct.model, fct.part_code, fct.part_name, fct.source,
    fct.gap AS fct_gap, act.gap AS act_gap,
    act.gap - fct.gap AS variance_gap,
    ABS(act.gap - fct.gap) AS abs_variance_gap,
    fct.cu_cr, act.cu_cr AS actual_status, act.reason
FROM bom_data fct
JOIN bom_data act
    ON fct.model = act.model AND fct.month = act.month AND fct.part_code = act.part_code
WHERE fct.version = 'forecast' AND act.version = 'actual';

CREATE OR REPLACE VIEW view_dmc_actual_trend AS
SELECT '2024-10' AS month, SUM(standard_cost_domestic + standard_cost_import) AS dmc_total
FROM model_master
UNION ALL
SELECT month, dmc_total FROM view_dmc_total_by_month WHERE version = 'actual';

CREATE OR REPLACE VIEW v_top_part_cu_cr AS
SELECT
    part_code, part_name,
    SUM(CASE WHEN cu_cr = 'cu' THEN gap ELSE 0 END) AS total_cu,
    SUM(CASE WHEN cu_cr = 'cr' THEN gap ELSE 0 END) AS total_cr,
    SUM(gap) AS net_gap
FROM bom_data
WHERE version = 'actual'
GROUP BY part_code, part_name;

CREATE OR REPLACE VIEW view_category_cu_cr AS
SELECT
    mm.category,
    SUM(CASE WHEN b.cu_cr = 'cu' THEN b.gap ELSE 0 END) AS total_cu,
    SUM(CASE WHEN b.cu_cr = 'cr' THEN b.gap ELSE 0 END) AS total_cr,
    SUM(b.gap) AS net_gap
FROM bom_data b
JOIN model_master mm ON b.model = mm.model
WHERE b.version = 'actual'
GROUP BY mm.category;