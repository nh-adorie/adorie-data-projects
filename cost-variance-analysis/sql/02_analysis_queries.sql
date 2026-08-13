SELECT part_code, part_name,
    COUNT(DISTINCT model) AS num_models_affected,
    SUM(CASE WHEN cu_cr = 'cu' THEN gap ELSE 0 END) AS total_cu
FROM bom_data
WHERE version = 'actual' AND cu_cr = 'cu'
GROUP BY part_code, part_name
HAVING num_models_affected > 1
ORDER BY total_cu DESC;

SELECT
    fct.cu_cr AS forecast_cu_cr,
    act.cu_cr AS actual_cu_cr,
    COUNT(*) AS num_rows
FROM bom_data fct
JOIN bom_data act
    ON fct.model = act.model AND fct.month = act.month AND fct.part_code = act.part_code
WHERE fct.version = 'forecast' AND act.version = 'actual'
GROUP BY fct.cu_cr, act.cu_cr;

SELECT month, cu_cr,
    SUM(gap_total) AS gap_total,
    SUM(gap_by_qty) AS gap_by_qty,
    SUM(gap_by_cu_cr_variance) AS gap_by_variance
FROM view_cu_cr
WHERE cu_cr IS NOT NULL
GROUP BY month, cu_cr
ORDER BY month, cu_cr;

SELECT
    d.model, mm.market,
    d.dmc_total AS dmc_amount,
    s.total_sales_m_vnd * 1000000 AS sales_amount,
    ROUND(d.dmc_total / (s.total_sales_m_vnd * 1000000) * 100, 1) AS dmc_pct_of_sales
FROM view_dmc_total_by_month d
JOIN view_sales s ON d.model = s.model AND d.month = s.month AND d.version = s.version
JOIN model_master mm ON d.model = mm.model
WHERE d.version = 'actual' AND d.month = '2025-02'
ORDER BY dmc_pct_of_sales;

SELECT month, model,
    SUM(gap_total) AS total_gap,
    ABS(SUM(gap_total)) AS abs_gap
FROM view_cu_cr
GROUP BY month, model
ORDER BY abs_gap DESC
LIMIT 20;

SELECT mm.category, d.month, d.version,
    SUM(d.dmc_total) AS dmc_total
FROM view_dmc_total_by_month d
JOIN model_master mm ON d.model = mm.model
GROUP BY mm.category, d.month, d.version
ORDER BY mm.category, d.month, d.version;