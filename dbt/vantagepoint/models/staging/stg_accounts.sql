{{ config(materialized='table') }}

select
    account_id,
    industry,
    annual_revenue,
    subscription_start_date,
    subscription_end_date,
    is_churned,
    tier,
    account_owner_id,
    datediff('day', subscription_start_date, coalesce(subscription_end_date, current_date())) as tenure_days -- Compute the tenure days
from {{ source('b2bsaas', 'accounts') }}