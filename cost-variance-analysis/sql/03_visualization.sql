-- ============================================================
-- 03_visualization.sql
-- Toàn bộ VIEW dùng để feed dữ liệu cho Power BI Dashboard
-- KHÔNG sửa các view này khi đang thử nghiệm (dùng 02_analysis_queries.sql)
-- Thứ tự chạy QUAN TRỌNG: view sau phụ thuộc view trước
-- ============================================================


-- ============================================================
-- DIMENSION: bảng tháng độc lập, dùng làm nguồn Slicer chung
-- KHÔNG dùng view fact nào khác làm nguồn slicer, tránh vỡ quan hệ
-- khi sửa view fact
-- ============================================================
CREATE OR REPLACE VIEW dim_month AS
SELECT DISTINCT month FROM bom_data
UNION
SELECT '2024-10' AS month;


-- ============================================================
-- VIEW NỀN TẢNG
-- ============================================================

-- view_sales: merge quantity + model_master + fx_rate, tính sales theo model/tháng
-- (đã tạo từ trước, giữ nguyên)
-- CREATE OR REPLACE VIEW view_sales AS ...


-- view_sales_gap_by_model: forecast vs actual sales, giữ chi tiết model/market để lọc được
CREATE OR REPLACE VIEW view_sales_gap_by_model AS
WITH forecast_data AS (SELECT * FROM view_sales WHERE version = 'forecast'),
actual_data AS (SELECT * FROM view_sales WHERE version = 'actual')
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
JOIN actual_data act ON fct.model = act.model AND fct.month = act.month;


-- view_cu_cr: forecast vs actual theo part, có reason/reason_category để drill xuống lý do
CREATE OR REPLACE VIEW view_cu_cr AS
WITH forecast_bom AS (SELECT * FROM bom_data WHERE version = 'forecast'),
actual_bom AS (SELECT * FROM bom_data WHERE version = 'actual'),
forecast_qty AS (SELECT * FROM quantity WHERE version = 'forecast'),
actual_qty AS (SELECT * FROM quantity WHERE version = 'actual')
SELECT 
    fct.month, fct.model, fct.part_code, fct.part_name,
    forecast_qty.quantity AS fct_qty, actual_qty.quantity AS act_qty,
    fct.gap AS fct, act.gap AS act,
    fct.cu_cr AS cu_cr,
    act.reason, act.reason_category,
    act.gap - fct.gap AS gap_per_unit,
    ((act.gap * actual_qty.quantity) - (fct.gap * forecast_qty.quantity)) / 1000000 AS gap_total,
    (actual_qty.quantity - forecast_qty.quantity) * fct.gap / 1000000 AS gap_by_qty,
    (act.gap - fct.gap) * actual_qty.quantity / 1000000 AS gap_by_cu_cr_variance
FROM forecast_bom fct
JOIN actual_bom act ON fct.month = act.month AND fct.model = act.model AND fct.part_code = act.part_code
JOIN forecast_qty ON fct.month = forecast_qty.month AND fct.model = forecast_qty.model
JOIN actual_qty ON act.month = actual_qty.month AND act.model = actual_qty.model;


-- view_dmc_model_month: DMC đơn vị (unit_dmc) và DMC amount (= unit_dmc x qty)
CREATE OR REPLACE VIEW view_dmc_model_month AS
SELECT b.version, b.model, b.month,
    SUM(b.tm_value) AS unit_dmc,
    q.quantity AS qty,
    SUM(b.tm_value) * q.quantity AS dmc_amount
FROM bom_data b
JOIN quantity q ON b.version = q.version AND b.model = q.model AND b.month = q.month
GROUP BY b.version, b.model, b.month, q.quantity;


-- view_dmc_total_by_month: giữ chi tiết model để lọc được (KHÔNG group theo tháng)
CREATE OR REPLACE VIEW view_dmc_total_by_month AS
SELECT month, model, version, dmc_amount AS dmc_total
FROM view_dmc_model_month;


-- view_dmc_bridge: Quantity Variance đúng công thức (nhân unit_dmc cả model)
CREATE OR REPLACE VIEW view_dmc_bridge AS
SELECT f.month, f.model,
    f.dmc_amount AS fct_amount,
    a.dmc_amount AS act_amount,
    (a.qty - f.qty) * f.unit_dmc AS qty_variance
FROM view_dmc_model_month f
JOIN view_dmc_model_month a ON f.model = a.model AND f.month = a.month
WHERE f.version = 'forecast' AND a.version = 'actual';


-- ============================================================
-- CARD: Quantity forecast/actual (giữ model để lọc được)
-- ============================================================
CREATE OR REPLACE VIEW view_quantity_summary AS
SELECT version, month, model, quantity AS total_qty
FROM quantity;


-- ============================================================
-- WATERFALL: Sales amount (giữ model/market để lọc được)
-- ============================================================
CREATE OR REPLACE VIEW view_sales_waterfall AS
SELECT month, model, market, 1 AS step_order, 'Sales Forecast' AS step, fct_sales AS value
FROM view_sales_gap_by_model
UNION ALL
SELECT month, model, market, 2, 'Quantity Variance', gap_by_qty
FROM view_sales_gap_by_model
UNION ALL
SELECT month, model, market, 3, 'FX Variance', gap_by_fx
FROM view_sales_gap_by_model;


-- ============================================================
-- WATERFALL: DMC (giữ model để lọc được)
-- ============================================================
CREATE OR REPLACE VIEW view_dmc_waterfall AS
SELECT month, model, 1 AS step_order, 'DMC Forecast' AS step, fct_amount / 1000000 AS value
FROM view_dmc_bridge
UNION ALL
SELECT month, model, 2, 'Quantity Variance', qty_variance / 1000000
FROM view_dmc_bridge
UNION ALL
SELECT month, model, 3, 'CU - Variance', gap_by_cu_cr_variance
FROM view_cu_cr WHERE cu_cr = 'cu'
UNION ALL
SELECT month, model, 4, 'CR - Variance', gap_by_cu_cr_variance
FROM view_cu_cr WHERE cu_cr = 'cr';


-- ============================================================
-- REPORT: CU/CR tổng quan theo tháng (đúng format báo cáo công ty)
-- CU Forecast - Actual - Gap (do qty / do variance)
-- ============================================================
CREATE OR REPLACE VIEW view_cu_cr_summary AS
SELECT month, cu_cr,
    SUM(gap_total) AS gap_total,
    SUM(gap_by_qty) AS gap_by_qty,
    SUM(gap_by_cu_cr_variance) AS gap_by_variance
FROM view_cu_cr
WHERE cu_cr IS NOT NULL
GROUP BY month, cu_cr;


-- ============================================================
-- REPORT: Part nổi cộm nhất trong phần Variance (không lẫn qty),
-- kèm reason để biết do VA/VE, Nego NCC, hay Market
-- ============================================================
CREATE OR REPLACE VIEW view_top_part_in_variance AS
SELECT month, cu_cr, part_code, part_name, reason, reason_category,
    SUM(gap_by_cu_cr_variance) AS variance_amount
FROM view_cu_cr
WHERE cu_cr IS NOT NULL
GROUP BY month, cu_cr, part_code, part_name, reason, reason_category;


-- ============================================================
-- REPORT: Model nào Gap (FCT vs ACT) lớn -> cần check kỹ BOM
-- Dùng làm nguồn cho Drillthrough sang view_bom_drilldown
-- ============================================================
CREATE OR REPLACE VIEW view_model_dmc_gap_flag AS
SELECT month, model,
    SUM(gap_total) AS total_gap,
    ABS(SUM(gap_total)) AS abs_gap
FROM view_cu_cr
GROUP BY month, model;


-- ============================================================
-- DRILLDOWN: BOM chi tiết, sort theo gap lớn nhất
-- ============================================================
CREATE OR REPLACE VIEW view_bom_drilldown AS
SELECT
    fct.month, fct.model, fct.part_code, fct.part_name, fct.source,
    fct.gap AS fct_gap, act.gap AS act_gap,
    act.gap - fct.gap AS variance_gap,
    ABS(act.gap - fct.gap) AS abs_variance_gap,
    fct.cu_cr, act.cu_cr AS actual_status, act.reason, act.reason_category
FROM bom_data fct
JOIN bom_data act
    ON fct.model = act.model AND fct.month = act.month AND fct.part_code = act.part_code
WHERE fct.version = 'forecast' AND act.version = 'actual';


-- ============================================================
-- LINE CHART: DMC actual amount theo thời gian (mốc gốc T10, đã SUM sẵn
-- vì chart này chỉ cần tổng công ty, không cần lọc theo model)
-- ============================================================
CREATE OR REPLACE VIEW view_dmc_actual_trend AS
SELECT '2024-10' AS month,
    SUM((mm.standard_cost_domestic + mm.standard_cost_import) * q.quantity) AS dmc_total
FROM model_master mm
JOIN quantity q ON q.model = mm.model AND q.month = '2024-11' AND q.version = 'forecast'
UNION ALL
SELECT month, SUM(dmc_total)
FROM view_dmc_total_by_month
WHERE version = 'actual'
GROUP BY month;


-- ============================================================
-- CHART: Top part CU/CR (cả năm, actual, mức đơn vị)
-- ============================================================
CREATE OR REPLACE VIEW view_top_part_cu_cr AS
SELECT part_code, part_name,
    SUM(CASE WHEN cu_cr = 'cu' THEN gap ELSE 0 END) AS total_cu,
    SUM(CASE WHEN cu_cr = 'cr' THEN gap ELSE 0 END) AS total_cr,
    SUM(gap) AS net_gap
FROM bom_data
WHERE version = 'actual'
GROUP BY part_code, part_name;


-- ============================================================
-- CHART: CU/CR theo category (cả năm, actual)
-- ============================================================
CREATE OR REPLACE VIEW view_category_cu_cr AS
SELECT mm.category,
    SUM(CASE WHEN b.cu_cr = 'cu' THEN b.gap ELSE 0 END) AS total_cu,
    SUM(CASE WHEN b.cu_cr = 'cr' THEN b.gap ELSE 0 END) AS total_cr,
    SUM(b.gap) AS net_gap
FROM bom_data b
JOIN model_master mm ON b.model = mm.model
WHERE b.version = 'actual'
GROUP BY mm.category;