-- Data Analysis
-- ============================================================
-- 1. ACCOUNTS
-- ============================================================

-- Total count + churn rate
SELECT
    COUNT(*)                                            AS total_accounts,
    SUM(CASE WHEN is_churned THEN 1 ELSE 0 END)        AS churned_count,
    ROUND(SUM(CASE WHEN is_churned THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 1) AS churn_rate_pct
FROM VANTAGEPOINT_PROD.B2BSAAS.ACCOUNTS;

-- Industry distribution
SELECT industry, COUNT(*) AS account_count
FROM VANTAGEPOINT_PROD.B2BSAAS.ACCOUNTS
GROUP BY industry
ORDER BY account_count DESC;

-- Tier distribution
SELECT tier, COUNT(*) AS account_count
FROM VANTAGEPOINT_PROD.B2BSAAS.ACCOUNTS
GROUP BY tier;

-- Churn rate by tier
SELECT
    tier,
    COUNT(*) AS total,
    SUM(CASE WHEN is_churned THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN is_churned THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 1) AS churn_rate_pct
FROM VANTAGEPOINT_PROD.B2BSAAS.ACCOUNTS
GROUP BY tier;


-- ============================================================
-- 2. OPPORTUNITIES —
-- ============================================================

-- Total count + deals per account range
SELECT
    COUNT(*)                                AS total_opportunities,
    COUNT(DISTINCT account_id)              AS accounts_with_deals,
    ROUND(COUNT(*)::FLOAT / COUNT(DISTINCT account_id), 1) AS avg_deals_per_account,
    MIN(deals) AS min_deals_per_account,
    MAX(deals) AS max_deals_per_account
FROM (
    SELECT account_id, COUNT(*) AS deals
    FROM VANTAGEPOINT_PROD.B2BSAAS.OPPORTUNITIES
    GROUP BY account_id
);

-- Stage distribution
SELECT stage, COUNT(*) AS opp_count,
    ROUND(COUNT(*)::FLOAT / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM VANTAGEPOINT_PROD.B2BSAAS.OPPORTUNITIES
GROUP BY stage
ORDER BY opp_count DESC;

-- Lead source distribution
SELECT lead_source, COUNT(*) AS opp_count
FROM VANTAGEPOINT_PROD.B2BSAAS.OPPORTUNITIES
GROUP BY lead_source
ORDER BY opp_count DESC;


-- ============================================================
-- 3. USAGE LOGS — 7,500 records, 12 features, ~62% error-free
-- ============================================================

-- Total count + date range
SELECT
    COUNT(*)            AS total_records,
    MIN(timestamp)      AS earliest,
    MAX(timestamp)      AS latest,
    COUNT(DISTINCT account_id) AS unique_accounts,
    COUNT(DISTINCT user_id)    AS unique_users
FROM VANTAGEPOINT_PROD.B2BSAAS.USAGE_LOGS;

-- Feature distribution (should be 12 distinct)
SELECT feature_used, COUNT(*) AS session_count
FROM VANTAGEPOINT_PROD.B2BSAAS.USAGE_LOGS
GROUP BY feature_used
ORDER BY session_count DESC;

-- Error rate
SELECT
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN error_codes_encountered IS NULL THEN 1 ELSE 0 END) AS error_free,
    ROUND(SUM(CASE WHEN error_codes_encountered IS NULL THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 1) AS error_free_pct,
    SUM(CASE WHEN error_codes_encountered IS NOT NULL THEN 1 ELSE 0 END) AS with_errors,
    ROUND(SUM(CASE WHEN error_codes_encountered IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 1) AS error_pct
FROM VANTAGEPOINT_PROD.B2BSAAS.USAGE_LOGS;

-- Error code breakdown
SELECT error_codes_encountered, COUNT(*) AS occurrences
FROM VANTAGEPOINT_PROD.B2BSAAS.USAGE_LOGS
WHERE error_codes_encountered IS NOT NULL
GROUP BY error_codes_encountered
ORDER BY occurrences DESC;



-- ============================================================
-- 4. TRANSCRIPTS — 650 records, 40/35/25 type split
-- ============================================================

-- Total count
SELECT COUNT(*) AS total_transcripts
FROM VANTAGEPOINT_PROD.B2BSAAS.INTERACTION_TRANSCRIPTS;

-- Type distribution (expect ~40% support, ~35% sales, ~25% email)
SELECT
    interaction_type,
    COUNT(*) AS tx_count,
    ROUND(COUNT(*)::FLOAT / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM VANTAGEPOINT_PROD.B2BSAAS.INTERACTION_TRANSCRIPTS
GROUP BY interaction_type
ORDER BY tx_count DESC;

-- Account ID vs Opportunity ID linkage
SELECT
    SUM(CASE WHEN account_id IS NOT NULL AND opportunity_id IS NULL THEN 1 ELSE 0 END) AS account_only,
    SUM(CASE WHEN account_id IS NULL AND opportunity_id IS NOT NULL THEN 1 ELSE 0 END) AS opportunity_only,
    SUM(CASE WHEN account_id IS NOT NULL AND opportunity_id IS NOT NULL THEN 1 ELSE 0 END) AS both,
    SUM(CASE WHEN account_id IS NULL AND opportunity_id IS NULL THEN 1 ELSE 0 END) AS neither
FROM VANTAGEPOINT_PROD.B2BSAAS.INTERACTION_TRANSCRIPTS;

-- Complaint category distribution (Bedrock-enriched)
SELECT complaint_category, COUNT(*) AS tx_count
FROM VANTAGEPOINT_PROD.B2BSAAS.INTERACTION_TRANSCRIPTS
WHERE complaint_category IS NOT NULL
GROUP BY complaint_category
ORDER BY tx_count DESC;

-- Sentiment score distribution
SELECT
    ROUND(AVG(sentiment_score), 3)  AS avg_sentiment,
    MIN(sentiment_score)            AS min_sentiment,
    MAX(sentiment_score)            AS max_sentiment,
    ROUND(MEDIAN(sentiment_score), 3) AS median_sentiment
FROM VANTAGEPOINT_PROD.B2BSAAS.INTERACTION_TRANSCRIPTS
WHERE sentiment_score IS NOT NULL;