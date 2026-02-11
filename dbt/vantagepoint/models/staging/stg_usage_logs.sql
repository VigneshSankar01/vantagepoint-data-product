{{ config(materialized='table') }}

select
    session_id,
    account_id,
    user_id,
    feature_used,
    session_duration_seconds,
    error_codes_encountered,
    timestamp
from {{ source('b2bsaas', 'usage_logs') }}
qualify row_number() over (partition by session_id order by timestamp desc) = 1