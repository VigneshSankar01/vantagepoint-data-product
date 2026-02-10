{{ config(materialized='table') }}

select
    a.account_id,
    a.industry,
    a.annual_revenue,
    a.tier,
    a.is_churned,
    a.tenure_days,
    a.account_owner_id,

    coalesce(u.total_sessions, 0) as total_sessions,
    coalesce(u.active_users, 0) as active_users,
    coalesce(u.features_adopted, 0) as features_adopted,
    coalesce(u.avg_session_duration, 0) as avg_session_duration,
    coalesce(u.error_rate, 0) as error_rate,
    coalesce(u.days_since_last_active, 999) as days_since_last_active,

    coalesce(t.avg_sentiment, 0) as avg_sentiment,
    coalesce(t.support_ticket_count, 0) as support_ticket_count,
    coalesce(t.negative_interaction_count, 0) as negative_interaction_count,
    coalesce(t.top_complaint_category, 'none') as top_complaint_category,

    round(
        (least(coalesce(u.total_sessions, 0), 100) / 100.0) * 15 +
        (least(coalesce(u.features_adopted, 0), 12) / 12.0) * 15 +
        (1 - least(coalesce(u.error_rate, 0), 1)) * 10 +
        (case
            when coalesce(u.days_since_last_active, 999) <= 7 then 20
            when coalesce(u.days_since_last_active, 999) <= 30 then 15
            when coalesce(u.days_since_last_active, 999) <= 90 then 8
            else 0
        end) +
        ((coalesce(t.avg_sentiment, 0) + 1) / 2.0) * 25 +
        (case
            when coalesce(t.support_ticket_count, 0) = 0 then 15
            when coalesce(t.support_ticket_count, 0) <= 3 then 10
            when coalesce(t.support_ticket_count, 0) <= 7 then 5
            else 0
        end)
    , 1) as health_score

from {{ ref('stg_accounts') }} a
left join {{ ref('int_usage_metrics') }} u on a.account_id = u.account_id
left join {{ ref('int_transcript_metrics') }} t on a.account_id = t.account_id