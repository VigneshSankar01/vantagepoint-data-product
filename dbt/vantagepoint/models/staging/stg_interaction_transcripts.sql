{{ config(materialized='table') }}

select
    interaction_id,
    account_id,
    opportunity_id,
    timestamp,
    interaction_type,
    transcript_body,
    sentiment_score,
    complaint_category
from {{ source('b2bsaas', 'interaction_transcripts') }}