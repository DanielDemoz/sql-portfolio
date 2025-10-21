-- =============================================
-- CUSTOMER ANALYTICS - RFM & SEGMENTATION
-- Advanced business intelligence queries
-- =============================================
-- Author: Daniel S. Demoz
-- Complexity: 🟠 Advanced
-- Use Case: E-commerce / Retail Analytics
-- =============================================

-- Note: This assumes an e-commerce schema with:
-- - customers table
-- - orders table
-- - order_items table
-- Adapt table/column names to your schema

-- =============================================
-- 1. RFM ANALYSIS (Recency, Frequency, Monetary)
-- =============================================

-- RFM is the gold standard for customer segmentation
-- Recency: How recently did they purchase?
-- Frequency: How often do they purchase?
-- Monetary: How much do they spend?

WITH customer_rfm_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        -- Recency: Days since last order
        CURRENT_DATE - MAX(o.order_date) AS days_since_last_order,
        -- Frequency: Number of orders
        COUNT(DISTINCT o.order_id) AS total_orders,
        -- Monetary: Total amount spent
        COALESCE(SUM(o.total_amount), 0) AS total_spent,
        -- Additional metrics
        AVG(o.total_amount) AS avg_order_value,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '2 years'  -- Last 2 years
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
),
rfm_scores AS (
    SELECT 
        *,
        -- Assign scores 1-5 (5 being best)
        NTILE(5) OVER (ORDER BY days_since_last_order ASC) AS recency_score,
        NTILE(5) OVER (ORDER BY total_orders) AS frequency_score,
        NTILE(5) OVER (ORDER BY total_spent) AS monetary_score
    FROM customer_rfm_metrics
),
rfm_segments AS (
    SELECT 
        *,
        -- Concatenate for easy reference
        CAST(recency_score AS VARCHAR) || CAST(frequency_score AS VARCHAR) || CAST(monetary_score AS VARCHAR) AS rfm_code,
        -- Assign strategic segments
        CASE 
            -- Champions: Recent, frequent, high spenders
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            
            -- Loyal Customers: Regular buyers, not necessarily high spenders
            WHEN recency_score >= 3 AND frequency_score >= 4 THEN 'Loyal Customers'
            
            -- Potential Loyalists: Recent customers, showing promise
            WHEN recency_score >= 4 AND frequency_score >= 2 AND frequency_score <= 3 THEN 'Potential Loyalists'
            
            -- Recent Customers: Bought recently but not frequently
            WHEN recency_score >= 4 AND frequency_score <= 1 THEN 'Recent Customers'
            
            -- Promising: Recent mid-level buyers
            WHEN recency_score >= 3 AND frequency_score <= 2 THEN 'Promising'
            
            -- Customers Needing Attention: Above average recency/frequency/monetary
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Customers Needing Attention'
            
            -- At Risk: Used to be good, haven't purchased recently
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
            
            -- Can't Lose Them: High spenders who haven't returned
            WHEN recency_score <= 1 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Can''t Lose Them'
            
            -- Hibernating: Low recent activity, were once active
            WHEN recency_score <= 2 AND frequency_score >= 2 AND frequency_score <= 3 THEN 'Hibernating'
            
            -- Lost: Haven't purchased in a long time
            WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost'
            
            ELSE 'Others'
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_id,
    customer_name,
    email,
    customer_segment,
    rfm_code,
    recency_score,
    frequency_score,
    monetary_score,
    days_since_last_order,
    total_orders,
    ROUND(total_spent, 2) AS total_spent,
    ROUND(avg_order_value, 2) AS avg_order_value,
    first_order_date,
    last_order_date,
    -- Recommended actions
    CASE 
        WHEN customer_segment = 'Champions' THEN 'Reward with exclusive offers, early access'
        WHEN customer_segment = 'Loyal Customers' THEN 'Upsell, cross-sell, loyalty program'
        WHEN customer_segment = 'Potential Loyalists' THEN 'Offer membership, recommend products'
        WHEN customer_segment = 'Recent Customers' THEN 'Onboard, provide support, build relationship'
        WHEN customer_segment = 'Promising' THEN 'Create brand awareness, special offers'
        WHEN customer_segment = 'At Risk' THEN 'Reactivation campaign, personalized offers'
        WHEN customer_segment = 'Can''t Lose Them' THEN 'Win-back campaign, survey feedback'
        WHEN customer_segment = 'Hibernating' THEN 'Special discount, new product announcements'
        WHEN customer_segment = 'Lost' THEN 'Ignore or aggressive win-back with high incentive'
        ELSE 'Monitor and nurture'
    END AS recommended_action
FROM rfm_segments
ORDER BY monetary_score DESC, frequency_score DESC, recency_score DESC;

-- =============================================
-- 2. CUSTOMER LIFETIME VALUE (CLV)
-- =============================================

-- Predictive CLV using historical data
WITH customer_history AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_order_value,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        MAX(order_date) - MIN(order_date) AS customer_lifespan_days
    FROM orders
    GROUP BY customer_id
),
clv_calculation AS (
    SELECT 
        customer_id,
        total_orders,
        ROUND(total_revenue, 2) AS historical_value,
        ROUND(avg_order_value, 2) AS avg_order_value,
        customer_lifespan_days,
        -- Average purchase frequency (orders per month)
        CASE 
            WHEN customer_lifespan_days > 0 
            THEN ROUND(total_orders::DECIMAL / (customer_lifespan_days / 30.0), 2)
            ELSE 0
        END AS avg_monthly_frequency,
        -- Estimated annual value
        CASE 
            WHEN customer_lifespan_days > 0 
            THEN ROUND((total_orders::DECIMAL / (customer_lifespan_days / 365.0)) * avg_order_value, 2)
            ELSE 0
        END AS estimated_annual_value,
        -- Predicted 3-year CLV (simplified model)
        CASE 
            WHEN customer_lifespan_days > 0 
            THEN ROUND((total_orders::DECIMAL / (customer_lifespan_days / 365.0)) * avg_order_value * 3, 2)
            ELSE 0
        END AS predicted_3year_clv
    FROM customer_history
    WHERE customer_lifespan_days >= 30  -- At least 1 month of history
)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    clv.total_orders,
    clv.historical_value,
    clv.avg_order_value,
    clv.customer_lifespan_days,
    clv.avg_monthly_frequency,
    clv.estimated_annual_value,
    clv.predicted_3year_clv,
    -- Value tier
    NTILE(10) OVER (ORDER BY clv.predicted_3year_clv DESC) AS value_decile,
    CASE 
        WHEN clv.predicted_3year_clv >= PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY clv.predicted_3year_clv) OVER () 
        THEN 'VIP'
        WHEN clv.predicted_3year_clv >= PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY clv.predicted_3year_clv) OVER () 
        THEN 'High Value'
        WHEN clv.predicted_3year_clv >= PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY clv.predicted_3year_clv) OVER () 
        THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_tier
FROM customers c
JOIN clv_calculation clv ON c.customer_id = clv.customer_id
ORDER BY clv.predicted_3year_clv DESC;

-- =============================================
-- 3. COHORT ANALYSIS
-- =============================================

-- Analyze customer retention by acquisition cohort
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
order_months AS (
    SELECT DISTINCT
        o.customer_id,
        cc.cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month
    FROM orders o
    JOIN customer_cohorts cc ON o.customer_id = cc.customer_id
),
cohort_data AS (
    SELECT 
        cohort_month,
        order_month,
        COUNT(DISTINCT customer_id) AS customers,
        (EXTRACT(YEAR FROM order_month) - EXTRACT(YEAR FROM cohort_month)) * 12 +
        (EXTRACT(MONTH FROM order_month) - EXTRACT(MONTH FROM cohort_month)) AS month_number
    FROM order_months
    GROUP BY cohort_month, order_month
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
)
SELECT 
    cd.cohort_month,
    cs.cohort_size,
    cd.month_number,
    cd.customers AS active_customers,
    ROUND(100.0 * cd.customers / cs.cohort_size, 2) AS retention_rate
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_number <= 12  -- First 12 months
ORDER BY cd.cohort_month, cd.month_number;

-- =============================================
-- 4. CHURN PREDICTION INDICATORS
-- =============================================

-- Identify customers likely to churn
WITH customer_activity AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        COUNT(o.order_id) AS total_orders,
        MAX(o.order_date) AS last_order_date,
        CURRENT_DATE - MAX(o.order_date) AS days_since_last_order,
        AVG(DATE_PART('day', o.order_date - LAG(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date))) AS avg_days_between_orders
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
)
SELECT 
    customer_id,
    customer_name,
    email,
    total_orders,
    last_order_date,
    days_since_last_order,
    ROUND(avg_days_between_orders, 0) AS avg_days_between_orders,
    -- Churn risk score
    CASE 
        WHEN days_since_last_order > 3 * avg_days_between_orders THEN 'High Risk'
        WHEN days_since_last_order > 2 * avg_days_between_orders THEN 'Medium Risk'
        WHEN days_since_last_order > 1.5 * avg_days_between_orders THEN 'Low Risk'
        ELSE 'Active'
    END AS churn_risk,
    -- Recommended action
    CASE 
        WHEN days_since_last_order > 3 * avg_days_between_orders THEN 'Immediate win-back campaign'
        WHEN days_since_last_order > 2 * avg_days_between_orders THEN 'Re-engagement email'
        WHEN days_since_last_order > 1.5 * avg_days_between_orders THEN 'Gentle reminder'
        ELSE 'Continue nurturing'
    END AS recommended_action
FROM customer_activity
WHERE total_orders > 1  -- Exclude one-time customers
  AND avg_days_between_orders IS NOT NULL
ORDER BY 
    CASE 
        WHEN days_since_last_order > 3 * avg_days_between_orders THEN 1
        WHEN days_since_last_order > 2 * avg_days_between_orders THEN 2
        WHEN days_since_last_order > 1.5 * avg_days_between_orders THEN 3
        ELSE 4
    END,
    days_since_last_order DESC;

-- =============================================
-- BUSINESS INSIGHTS
-- =============================================

/*
These analytics enable:

1. RFM Segmentation
   - Identify best customers
   - Tailor marketing campaigns
   - Allocate resources effectively

2. CLV Analysis
   - Focus on high-value customers
   - Set acquisition cost budgets
   - Predict future revenue

3. Cohort Analysis
   - Measure retention over time
   - Identify successful acquisition periods
   - Track product/market fit

4. Churn Prediction
   - Proactive customer retention
   - Reduce churn rate
   - Increase customer lifetime

Key Metrics to Monitor:
- Retention Rate: >40% at month 3 is healthy
- CLV:CAC Ratio: Should be >3:1
- Churn Rate: <5% monthly is excellent
- Avg Order Value: Track for trends
*/

