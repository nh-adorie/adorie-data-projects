# Telco Customer Churn

# **Introduction**

## Background

Customer churn is a critical challenge in the telecommunications industry. Acquiring new customers costs significantly more than retaining existing ones.

> "The acquisition cost is 5 times that of the retention cost."  
> — Sharmila K. Wagh et al., 2023

With massive amounts of customer data generated daily, predicting churn becomes essential for maintaining profitability and sustainable growth.

## Dataset
This project analyzes the **Telco Customer Churn dataset** from [Kagglehub](https://www.kaggle.com/datasets/blastchar/telco-customer-churn/data), which contains information about:
- Customer demographics (gender, age, dependents)
- Services subscribed (phone, internet, streaming)
- Account information (contract type, payment method, tenure)
- Churn status (whether customer left within the last month)

## Objective
Predict which customers are likely to churn, enabling the company to:
- Identify at-risk customers early
- Develop targeted retention strategies
- Reduce customer attrition and increase lifetime value

## Approach
This project compares two modeling approaches:
1. **Logistic Regression**: Traditional statistical approach
2. **Tree-based Models**: Decision Tree and Random Forest

By comparing these methods, we aim to find the most effective model for churn prediction.



# EDA

## Dataset Overview 
-  **Size:** 7,043 customers, 21 features 
- **Target variable:** Churn (Yes/No) 
-  **Class distribution:** 73% non-churn, 27% churn (imbalanced) 
-  **Data quality:** No missing values, no duplicates

## Key Findings from EDA 
### 1. Contract Type is the Strongest Predictor 
![Churn Rate by Contract](telco-customer-churn/visualization/churn_by_contract.png)
**Insight:** Month-to-month contracts show 42% churn rate, significantly higher than one-year (11%) and two-year (3%) contracts. 
### 2. Early Customers are at Highest Risk
![Churn rate by Tenure](telco-customer-churn/visualization/churn_by_tenure.png) 
**Insight:** Customers with tenure < 12 months account for 50% of all churns. Early customer engagement is critical.
### 3. Payment Method Matters
![Churn rate by Payment method](image-2.png)
**Insight:** Electronic check users churn at 45%, much higher than other payment methods (15-18%).
### 4. Higher Charges Correlate with Churn 
![Churn vs Monthly Charges](image-3.png)
**Insight:** Churned customers pay an average of $74/month, compared to $61/month for retained customers.

*For detailed analysis, see the full notebook.*

# Logistics Regression Model

Trình bày confusion matrix và classification report for logistic regression model: precision    recall  f1-score   support

# Tree-based Model

## Round 1: Include all variables as features
### Decision Tree 
-  **Best CV Score (AUC):** 0.82  
-   **Best Parameters:**  `max_depth=4, min_samples_leaf=2, min_samples_split=2` 
- **Test Set Performance:** 

| Metric | Non-Churn | Churn | 
|-----------|-----------|-------| 
| Precision | 0.81 | 0.63 | 
| Recall | 0.92 | 0.39 | 
| F1-Score | 0.86 | 0.48 |


**→ Overall Accuracy:** 0.78


### Random Forest 
-  **Best CV Score (AUC):** 0.82  
-   **Best Parameters:**  `max_depth=4, min_samples_leaf=2, min_samples_split=2` 
- **Test Set Performance:** 

| Metric | Non-Churn | Churn | 
|-----------|-----------|-------| 
| Precision | 0.81 | 0.63 | 
| Recall | 0.92 | 0.39 | 
| F1-Score | 0.86 | 0.48 |


**→ Overall Accuracy:** 0.78

## Round 2:  Incorporate feature engineering to build improved models
### Decision Tree 
-  **Best CV Score (AUC):** 0.82  
-   **Best Parameters:**  `max_depth=4, min_samples_leaf=2, min_samples_split=2` 
- **Test Set Performance:** 

| Metric | Non-Churn | Churn | 
|-----------|-----------|-------| 
| Precision | 0.82 | 0.60 | 
| Recall | 0.89 | 0.45 | 
| F1-Score | 0.85 | 0.52 |


**→ Overall Accuracy:** 0.78


### Random Forest 
-  **Best CV Score (AUC):** 0.82  
-   **Best Parameters:**  `max_depth=4, min_samples_leaf=2, min_samples_split=2` 
- **Test Set Performance:** 

| Metric | Non-Churn | Churn | 
|-----------|-----------|-------| 
| Precision | 0.81 | 0.63 | 
| Recall | 0.92 | 0.39 | 
| F1-Score | 0.86 | 0.48 |

# Key Findings

## Model Performance Comparison


| Model | CV AUC | Test Accuracy | Churn Precision | Churn Recall | Churn F1 | 
|------------------------|--------|---------------|-----------------|--------------|----------| 
| Logistic Regression | 0.XX | 0.74 | 0.50 | 0.81 | 0.62 | 
| Decision Tree (R1) | 0.82 | 0.78 | 0.63 | 0.39 | 0.48 | 
| Random Forest (R1) | 0.XX | 0.XX | 0.XX | 0.XX | 0.XX | 
| Decision Tree (R2) | 0.XX | 0.XX | 0.XX | 0.XX | 0.XX | 
| Random Forest (R2) | 0.XX | 0.XX | 0.XX | 0.XX | 0.XX | 

**Note:** R1 = Round 1 (all features), R2 = Round 2 (feature engineered)

## Best Model 
**[Tên model tốt nhất]** achieves the best balance between precision and recall for churn prediction. 
**Why this model?** 
- [Lý do 1: ví dụ highest F1 score for churn class] 
- [Lý do 2: ví dụ good balance between false positives and false negatives] 
-  [Lý do 3: ví dụ suitable for business objective]

## Key Insights
1. **Contract Type:** Month-to-month contracts have significantly higher churn rates 
2.  **Tenure:** Customers with < 12 months tenure are most at-risk 
3.  **Payment Method:** Electronic check users churn more frequently 
4. **[Thêm insights khác từ EDA của bạn]**

## Business Recommendations 
1.  **Target retention campaigns** at customers with month-to-month contracts 
2.  **Offer incentives** to convert short-tenure customers to longer contracts 
3. **Improve payment experience** for electronic check users 
4. **[Thêm recommendations khác]**

# Tools & Libraries 
- Python 3.x 
- pandas, NumPy 
- scikit-learn 
- matplotlib, seaborn 
- imbalanced-learn 

# Author 
[Adorie] [LinkedIn]