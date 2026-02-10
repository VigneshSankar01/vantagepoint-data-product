{{ config(materialized='table') }}

select
    account_id,
    round(avg(sentiment_score), 3) as avg_sentiment,
    min(sentiment_score) as worst_sentiment,
    count(*) as total_interactions,
    sum(case when interaction_type = 'support_ticket' then 1 else 0 end) as support_ticket_count,
    sum(case when interaction_type = 'sales_call' then 1 else 0 end) as sales_call_count,
    sum(case when interaction_type = 'email' then 1 else 0 end) as email_count,
    mode(complaint_category) as top_complaint_category,
    sum(case when sentiment_score < -0.3 then 1 else 0 end) as negative_interaction_count
from {{ ref('stg_interaction_transcripts') }}
where account_id is not null
group by account_id