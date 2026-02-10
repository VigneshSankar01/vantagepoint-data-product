{{ config(materialized='table') }}

select
    opportunity_id,
    account_id,
    product_code,
    stage,
    amount_gbp,
    close_date,
    lead_source
from {{ source('b2bsaas', 'opportunities') }}