{{ config(materialized='table') }}

with complaint_ranked as (
    select
        account_id,
        complaint_category,
        count(*) as category_count,
        min(sentiment_score) as worst_sentiment,
        max(timestamp) as most_recent,
        row_number() over (
            partition by account_id
            order by
                count(*) desc,
                min(sentiment_score) asc,
                max(timestamp) desc
        ) as rn
    from {{ ref('stg_interaction_transcripts') }}
    where account_id is not null
      and complaint_category is not null
    group by account_id, complaint_category
)

select
    t.account_id,
    round(avg(t.sentiment_score), 3) as avg_sentiment,
    min(t.sentiment_score) as worst_sentiment,
    count(*) as total_interactions,
    sum(case when t.interaction_type = 'support_ticket' then 1 else 0 end) as support_ticket_count,
    sum(case when t.interaction_type = 'sales_call' then 1 else 0 end) as sales_call_count,
    sum(case when t.interaction_type = 'email' then 1 else 0 end) as email_count,
    cr.complaint_category as top_complaint_category,
    sum(case when t.sentiment_score < -0.3 then 1 else 0 end) as negative_interaction_count
from {{ ref('stg_interaction_transcripts') }} t
left join complaint_ranked cr
    on t.account_id = cr.account_id and cr.rn = 1
where t.account_id is not null
group by t.account_id, cr.complaint_category