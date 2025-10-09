# SCM Co Smart Project

## Overview
This project analyzes the SCM Co Smart dataset to understand sales performance, profitability, and customer behavior patterns.

## Objectives
- Clean and explore the dataset
- Identify key patterns and anomalies
- Create meaningful visualizations and insights
- Build a Power BI dashboard for presentation

## Data
The dataset contains order, product, and customer details from an e-commerce platform.

Key columns include:
- order_id, order_item_total, order_item_profit_ratio, sales, shipping_mode, etc.

## Process
1. **Data Cleaning & EDA**  
   Notebook: [01_data_cleaning_eda.ipynb](./notebooks/01_data_cleaning_eda.ipynb)  
   Steps:
   - Handle duplicates and missing values
   - Identify correlated columns and outliers
   - Explore category-level profit patterns

2. **Analysis**  
   Notebook: [02_analysis.ipynb](./notebooks/02_analysis.ipynb)  
   - Profitability by category and shipping mode
   - Customer segmentation

3. **Visualization & Dashboard**  
   - Power BI dashboard: [Dashboard File](./dashboard/powerbi_dashboard.pbix)
   - Key charts: `images/`

4. **Insights Summary**  
   Report: [Insights Summary (PDF)](./reports/insights_summary.pdf)

## Key Findings
- Certain product categories (e.g. Cleats, Footwear) show negative profit margins.
- Outliers reveal possible pricing or discounting issues.
- Shipping mode correlates with delivery delays and profitability.

## Tools Used
Python (Pandas, Matplotlib), Power BI, Excel
