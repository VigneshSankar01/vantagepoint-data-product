{{ config(materialized='table') }}

select
    account_id,
    count(distinct session_id) as total_sessions,
    count(distinct user_id) as active_users,
    count(distinct feature_used) as features_adopted,
    round(avg(session_duration_seconds), 2) as avg_session_duration,
    sum(case when error_codes_encountered is not null then 1 else 0 end) as total_errors,
    round(
        sum(case when error_codes_encountered is not null then 1 else 0 end)::float 
        / nullif(count(*), 0), 4
    ) as error_rate,
    max(timestamp) as last_active_at,
    datediff('day', max(timestamp), current_timestamp()) as days_since_last_active
from {{ ref('stg_usage_logs') }}
group by account_id