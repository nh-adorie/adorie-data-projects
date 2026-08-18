# Cost Variance Analysis

A SQL + Power BI project simulating the monthly Cost Variance Analysis workflow of a Cost Management team at a home-appliance manufacturer — the same analysis I performed manually in Excel/Power Query during 1.5 years working in Cost Management at a manufacturing company. This project rebuilds that workflow with a proper semantic layer in SQL and an interactive Power BI report, to practice doing the analysis the way a dedicated data tool would.

## Background

Every month, the company sets a **forecast** for production quantity and **DMC (Direct Material Cost)** for each product model. By month-end, **actual** figures always deviate from forecast. The Cost Management team's job is to:

1. **Measure the gap** between Forecast and Actual for both Sales and DMC.
2. **Decompose the causes of the gap** — is it driven by a change in *production quantity* (Quantity Variance), a change in *component price* (CU/CR Variance), or *FX rate movement* (FX Variance)?
3. **Trace down to part level** — which parts are experiencing **Cost Up (CU)** or **Cost Down (CR)**, and why (supplier negotiation, design change, or market conditions)?
4. **Assign accountability** — is a CR the result of internal effort (Purchasing/R&D — Operational-driven / Engineering-driven), or is a CU driven by external, uncontrollable market factors (Market-driven)?

This is a key report for leadership: it shows whether the team is effectively controlling cost and how exposed the business is to market risk.

## Dataset

**All data in this project is fully synthetic.** It does not represent real figures from any company, for confidentiality reasons. The structure and relationships between tables, however, mirror a real BOM/forecast reporting setup.

### Tables

| Table | Description |
|---|---|
| `bom_data` | Part-level price movement, by model, by month, by version (forecast/actual). Includes the reason for each change (`reason`) and its category (`reason_category`). |
| `model_master` | Fixed attributes per model: category, market, standard cost, selling price (`exf`), USD/JPY import share. |
| `fx_rate` | Monthly USD/JPY exchange rates, separated by forecast and actual. |
| `quantity` | Production quantity by model, by month, forecast and actual. |

### Data Architecture

The data model follows a simple **star schema**:
- **Dimensions:** `dim_month` (month list), `model_master` (model/category/market attributes)
- **Facts:** `bom_data`, `quantity`, `fx_rate`

## Approach

1. Designed a synthetic dataset that mirrors the real BOM/forecast structure I worked with previously, including forecast vs. actual versioning at part level.
2. Wrote raw-table analysis queries first (`02_analysis_queries.sql`) to explore the data and confirm the business logic before building anything reusable.
3. Built a **SQL semantic layer** (`03_visualization.sql`) — a set of views, each answering one specific business question (sales/DMC variance decomposition, CU/CR accountability, part-level drilldown, top-variance models). Power BI connects directly to these views rather than to raw tables, keeping the report's DAX minimal and centralizing all business logic in SQL where it's easier to test and version.
4. Validated the logic iteratively rather than trusting it once it ran without errors — including catching and fixing a Top-N ranking bug during the Power BI build (see **Lessons Learned**).
5. Designed the report as two pages with a clear zoom-in structure: Page 1 (Overview) surfaces *which model* needs attention; Page 2 (CU/CR Details) drills into *which part, and why*.

## SQL Techniques Used

| Technique | Where it's used | Business question it answers |
|---|---|---|
| **Window function** — `RANK() OVER (PARTITION BY month ORDER BY ...)` | `view_top_gap_by_month` | Which models had the largest cost variance, *for each month separately*? |
| **CTE (`WITH`)** | `view_cu_cr`, `view_sales_gap_by_model`, `view_dmc_bridge` | Structuring forecast-vs-actual comparisons before joining |
| **Self-join pattern (via CTE)** | `view_cu_cr`, `view_bom_drilldown` | Comparing the same table's forecast and actual rows side by side, matched on model/month/part |
| **Multi-table joins across fact + dimension tables** | `view_dmc_total_by_month` joined with `model_master` | Rolling up DMC variance by product category |
| **Views as a semantic layer** | All of `03_visualization.sql` | Keeping Power BI's DAX thin — logic lives in SQL, not scattered across measures |
| **`REGEXP` pattern matching** | Reason-category validation query | Cross-checking whether the recorded `reason_category` actually matches keywords in the free-text `reason` field, as a data-quality check |

*(See `02_analysis_queries.sql` and `03_visualization.sql` for full query text.)*

## Key Findings

![Overview Dashboard](./powerbi/01_overview_dashboard.png)
*Page 1 — Overview: Sales & DMC variance at a glance, with a dynamic waterfall breakdown by quantity, FX, and cost variance.*

![CU/CR Details Page](./powerbi/02_cu_cr_details.png)
*Page 2 — CU/CR Details: variance broken down by reason category (Market/Operational/Engineering-driven), part level, and model/month drilldown.*

- **Concentration risk from shared parts (platform sharing):** some parts are shared across up to 15 models at once, so any price movement in these parts ripples across multiple product lines rather than staying contained to a single model.
  → *Recommendation: prioritize CU/CR negotiation review for shared parts first, since their impact multiplies across the whole product portfolio.*

- **Category C shows the highest total DMC variance for the year**, largely driven by model C8, whose actual volume exceeded plan by +9.4% — showing how volume variance and cost variance can compound one another rather than being independent risks.
  → *Recommendation: when volume beats forecast significantly, re-check cost assumptions for that model specifically, since higher volume can expose CU parts that were immaterial at forecast-level quantity.*

- **Clear separation of CU/CR accountability by cause:** most CR (cost down) stems from internal effort (negotiation, design improvement), while CU (cost up) is mostly driven by external market factors.
  → *Recommendation: report CU and CR separately to leadership rather than netting them — the team should be evaluated on CR performance, while CU should be tracked as a market-exposure metric, not a team KPI miss.*

## Lessons Learned

- **A semantic layer pays off fast.** Pushing all forecast-vs-actual join and variance logic into SQL views — instead of building it inside Power BI with DAX — made the report far easier to debug and test independently of the visualization layer.
- **Aggregation context bugs are easy to miss.** A Top-N filter that worked correctly when a single month was selected silently broke when the report defaulted to "All months": ranking was computed per (month, model), but the visual displayed a `SUM(total_gap)` at the model level — a mismatch between the grain of the filter and the grain of the display. Fixed by (1) locking the report to a single-month context via a bookmark, and (2) adding a separate aggregate-first ranking view (`view_top_gap_overall`) for true all-time comparisons.
- **RANK vs. ROW_NUMBER is a deliberate choice, not a default.** Used `RANK()` instead of `ROW_NUMBER()` for the Top-N views so that tied variance values are never silently dropped from the leaderboard — appropriate for a report leadership uses to flag risk, where hiding a tied model is worse than showing an extra row.

## Repo Structure

```
├── data/                      # synthetic CSV source files
├── 01_load_all_data.sql       # schema definition + data loading
├── 02_analysis_queries.sql    # exploratory business-question queries
├── 03_visualization.sql       # semantic layer (views) powering Power BI
├── powerbi/                   # .pbix file + dashboard screenshots
└── README.md
```

## Tools

- **MySQL** — data modeling, semantic layer (views), analysis queries
- **Power BI Desktop** — interactive dashboard, DAX measures
- **Git / GitHub** — version control
