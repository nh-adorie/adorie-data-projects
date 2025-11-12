# Customer Segmentation Analysis

## Project Overview
Analysis of 2,240 customers to identify distinct segments and optimize marketing strategies using K-Means clustering.

## Key Findings

### Data Overview
- **Dataset**: 2,240 customers with 29 features
- **Key variables**: Demographics, spending behavior, channel preferences, campaign responses

### Exploratory Data Analysis Insights

**Income & Spending Patterns:**
- Strong correlation between income and spending (r=0.81)
- High-income customers spend 17x more than low-income customers
- Wine and meat products are primary spending categories for premium customers

**Channel Behavior:**
- **The Web Visits Paradox**: High website traffic ≠ High purchases
  - Finding: Customers with 6+ monthly web visits often have lower conversion rates
  - Implication: Potential website UX or pricing issues for browsers

**Campaign Effectiveness:**
- Overall low correlation between campaigns (< 0.40)
- Campaign 3 performed distinctly different from others (-0.08 correlation with Campaign 4)
- No clear "always responds" customer segment identified

### Customer Segmentation Results

**3 Distinct Segments Identified - K = 3:**

| Segment | Size | Avg Income | Avg Spending | Key Characteristic |
|---------|------|------------|--------------|-------------------|
| **Premium Omnichannel** | 34% | $72,831 | $1,245 | High-value, multi-channel |
| **Budget Browsers** | 41% | $33,437 | $71 | High traffic, low conversion |
| **Deal Seekers** | 25% | $52,856 | $592 | Price-sensitive, digital-first |

**Critical Insight**: 
- 34% of customers generate ~70% of revenue
- 41% of customers contribute only ~5% of revenue despite being the largest segment

## Strategic Recommendations

**Immediate Actions:**
1. **Premium Segment (34%)**: Implement VIP programs, reduce promotional noise
2. **Budget Browsers (41%)**: Investigate conversion barriers - potential product/pricing mismatch
3. **Deal Seekers (25%)**: Test loyalty programs to reduce discount dependency

**Revenue Optimization:**
- Focus retention on Premium segment (high-value, high-risk)
- Address conversion issues for Budget Browsers (largest segment, untapped potential)
- Improve margins for Deal Seekers (reduce deal dependency)

**4 Distinct Segments Identified - K = 4:**

| Segment | Size | Avg Income | Avg Spending | Key Characteristic |
|---------|------|------------|--------------|-------------------|
| **Digital-First Value Shoppers** | 17% | $63,917 | $1,039 | Web-dominant, high spenders |
| **Budget-Conscious Browsers** | 38% | $32,889 | $63 | High traffic, minimal conversion |
| **Moderate Deal Seekers** | 21% | $49,218 | $451 | Price-sensitive, deal-dependent |
| **Premium Omnichannel Loyalists** | 24% | $75,939 | $1,301 | Highest value, lowest deals |

**Critical Insights**: 
- 24% of customers (Premium Loyalists) generate ~44% of revenue
- 17% of customers (Digital-First) generate ~32% of revenue  
- 38% of customers contribute only ~5% of revenue despite being the largest segment
- **The Web Visits Paradox:** Premium customers visit website least (2.3x/month) but spend most ($1,301), while Budget Browsers visit most (6.4x/month) but spend least ($63)

## Strategic Recommendations

**Immediate Actions:**
1. **Premium Loyalists (24%)**: Implement VIP retention programs, eliminate promotional noise, maintain omnichannel excellence
2. **Digital-First Shoppers (17%)**: Optimize web/mobile experience, reduce deal dependency for margin improvement
3. **Budget Browsers (38%)**: Urgent investigation of conversion barriers - potential product/pricing mismatch or UX issues
4. **Deal Seekers (21%)**: Test loyalty programs to reduce discount dependency, improve margins through spend-threshold promotions

**Revenue Optimization:**
- Protect Premium Loyalists (highest value, highest churn risk)
- Address severe conversion crisis for Budget Browsers (largest segment, massive untapped potential)
- Migrate Deal Seekers from discounts to loyalty rewards (margin improvement opportunity)
- Enhance digital channels for Digital-First Shoppers (leverage web dominance for upselling)