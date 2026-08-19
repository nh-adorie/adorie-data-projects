# Telco Customer Churn

## Introduction

### Background

Customer churn is a critical challenge in the telecommunications industry. Acquiring new customers costs significantly more than retaining existing ones.

> "The acquisition cost is 5 times that of the retention cost."
> Sharmila K. Wagh et al., 2023

With massive amounts of customer data generated daily, predicting churn becomes essential for maintaining profitability and sustainable growth.

### Dataset

This project analyzes the **Telco Customer Churn dataset** from [Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn/data), which contains information about:
- Customer demographics (gender, age, dependents)
- Services subscribed (phone, internet, streaming)
- Account information (contract type, payment method, tenure)
- Churn status (whether the customer left within the last month)

**Size:** 7,043 customers, 21 features · **Target:** Churn (Yes/No) · **Class balance:** 73% non-churn / 27% churn · **Data quality:** no missing values after cleaning, no duplicates

### Objective

Predict which customers are likely to churn, enabling the company to:
- Identify at-risk customers early
- Develop targeted retention strategies
- Reduce customer attrition and increase lifetime value

### Approach

1. Cleaned and explored the data (type conversion, missing-value handling, outlier check via boxplots).
2. Ran univariate and interaction EDA (churn rate by category, by tenure bucket, by combinations of variables) to surface the strongest churn drivers before touching any model.
3. Compared two modeling families: **Logistic Regression** and **tree-based models** (Decision Tree, Random Forest). Trained with the same train/test split and cross-validation setup for a like-for-like comparison.
4. Applied `class_weight='balanced'` consistently across **all** models, since the dataset's 73/27 class split would otherwise bias every model toward the majority (non-churn) class regardless of algorithm.
5. Ran a second modeling round with engineered features (tenure buckets, charge tiers, service count) to test whether simplifying/aggregating raw features improved performance.
6. Selected a final model based on a combination of predictive performance and business-facing criteria (interpretability, simplicity) rather than on the single highest metric alone.

## EDA - Key Findings

### 1. Contract Type is the Strongest Predictor
<img src="visualization/churn_by_contract.png" alt="contract" width="500"/>

**Insight:** Month-to-month contracts show a 42% churn rate, significantly higher than one-year (11%) and two-year (3%) contracts.

### 2. Early-Tenure Customers are at Highest Risk
<img src="visualization/churn_by_tenure.png" alt="tenure" width="500"/>

**Insight:** Customers with tenure < 12 months account for 50% of all churns. Early customer engagement is critical.

### 3. Payment Method Matters
<img src="visualization/churn_by_payment.png" alt="payment" width="500"/>

**Insight:** Electronic check users churn at 45%, much higher than other payment methods (15–18%).

### 4. Higher Charges Correlate with Churn
<img src="visualization/churn_by_monthlycharges.png" alt="charges" width="500"/>

**Insight:** Churned customers pay an average of $74/month, compared to $61/month for retained customers.

*For the full breakdown (including gender, senior citizen status, and add-on services), see the notebook.*

## Modeling

All models below were trained with `class_weight='balanced'` to address the 73/27 class imbalance in the target variable, so that performance differences reflect the algorithms themselves rather than unequal handling of the minority class.

### Logistic Regression

**Confusion Matrix**
<img src="visualization/confusion_matrix.png" alt="confusion matrix" width="400"/>

| | Predicted Non-Churn | Predicted Churn |
|---|---|---|
| **Actual Non-Churn** | TN = 918 | FP = 373 |
| **Actual Churn** | FN = 91 | TP = 376 |

- **FP (373):** customers flagged as at-risk who actually stayed - a false alarm, costing an unnecessary retention outreach.
- **FN (91):** customers who churned but weren't flagged - a missed churner, costing the customer entirely.
- Since missing a churner (FN) is materially more costly than a false alarm (FP) for a retention program, **recall on the churn class is the priority metric** for this problem.

| Metric | Non-Churn | Churn |
|---|---|---|
| Precision | 0.91 | 0.50 |
| Recall | 0.71 | 0.81 |
| F1-Score | 0.80 | 0.62 |

**CV AUC:** 0.83 · **Test Accuracy:** 0.74

### Tree-based Models — Round 1 (all features)

| Model | CV AUC | Test Accuracy | Churn Precision | Churn Recall | Churn F1 |
|---|---|---|---|---|---|
| Decision Tree | 0.83 | 0.75 | 0.52 | 0.74 | 0.61 |
| Random Forest | 0.84 | 0.74 | 0.51 | 0.80 | 0.62 |

*Best parameters — Decision Tree: `max_depth=4, min_samples_leaf=2, min_samples_split=2`*

### Tree-based Models — Round 2 (engineered features)

Engineered features: `tenure_group` (binned tenure), `charge_category` (binned monthly charges), `num_services` (count of subscribed add-on services), replacing the corresponding raw columns.

| Model | CV AUC | Test Accuracy | Churn Precision | Churn Recall | Churn F1 |
|---|---|---|---|---|---|
| Decision Tree | 0.82 | 0.75 | 0.52 | 0.74 | 0.61 |
| Random Forest | 0.83 | 0.74 | 0.51 | 0.81 | 0.62 |

**Feature engineering did not meaningfully improve performance** over the raw-feature models. A likely explanation: tree-based models already split continuous variables like `Tenure` and `MonthlyCharges` at their own optimal thresholds during training, so manually binning them beforehand mostly discards information the trees could otherwise use — rather than adding signal.

## Key Findings

### Model Performance Comparison

| Model | CV AUC | Test Accuracy | Churn Precision | Churn Recall | Churn F1 |
|---|---|---|---|---|---|
| Logistic Regression | 0.83 | 0.74 | 0.50 | 0.81 | 0.62 |
| Decision Tree (R1) | 0.83 | 0.75 | 0.52 | 0.74 | 0.61 |
| Random Forest (R1) | 0.84 | 0.74 | 0.51 | 0.80 | 0.62 |
| Decision Tree (R2) | 0.82 | 0.75 | 0.52 | 0.74 | 0.61 |
| Random Forest (R2) | 0.83 | 0.74 | 0.51 | 0.81 | 0.62 |

*R1 = Round 1 (all features), R2 = Round 2 (engineered features). All models trained with `class_weight='balanced'`.*

### Best Model

Performance is fairly close across all five models. Churn recall ranges from 0.74 to 0.81, and F1 stays within 0.61–0.62. Given this, **Logistic Regression** is selected as the final model, based on:

- **Comparable recall and AUC** to the best-performing tree-based models
- **Interpretability:** coefficients give a direct, signed read on which features increase or decrease churn odds — useful for a retention team that needs actionable explanations, not just a prediction
- **Simplicity:** faster to train, fewer hyperparameters to maintain, easier to explain to non-technical stakeholders

### Key Insights

- **Contract Type**: customers on month-to-month contracts show significantly higher churn rates than one-year and two-year contracts.
- **Tenure**: customers with less than 12 months of tenure are the most at risk of churn, indicating early-stage customer experience is critical.
- **Payment Method**: customers using electronic check exhibit higher churn rates than those using automatic payment methods such as credit card or bank transfer.
- **Add-on Services**: customers who don't subscribe to additional services (e.g., online security, tech support) tend to churn more frequently, suggesting lower engagement.

### Business Recommendations

- **Target month-to-month customers with retention campaigns**: offer contract upgrade incentives or loyalty benefits to encourage longer-term commitments.
- **Focus on early-tenure customer engagement**: implement onboarding programs and proactive support during the first 12 months to reduce early churn.
- **Improve the electronic payment experience**: promote automatic payment methods and address potential friction points associated with electronic checks.
- **Increase service bundling and engagement**: encourage adoption of value-added services to strengthen customer attachment and reduce churn likelihood.

## Lessons Learned

- **Control for confounding factors before comparing models.** Imbalance handling (`class_weight='balanced'`) needs to be applied consistently across every model being compared — otherwise, differences in performance may reflect an inconsistent setup rather than a genuine advantage of one algorithm over another.
- **Feature engineering isn't automatically an improvement.** Binning continuous variables can *remove* information that tree-based models would otherwise use more effectively on their own, especially when the raw feature already carries a clean, learnable signal.
- **Recall vs. precision is a business decision, not just a statistic.** For churn prediction, a missed churner (false negative) is typically far costlier than a false alarm (false positive). This justified prioritizing recall over raw accuracy throughout the model selection process.

## Tools & Libraries

- Python
- pandas, NumPy
- scikit-learn
- matplotlib, seaborn
- imbalanced-learn
