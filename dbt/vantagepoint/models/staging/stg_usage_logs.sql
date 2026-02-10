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