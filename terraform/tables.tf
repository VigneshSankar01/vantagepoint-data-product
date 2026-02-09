resource "snowflake_table" "accounts" {
  database = snowflake_database.prod.name
  schema   = snowflake_schema.b2bsaas.name
  name     = "ACCOUNTS"

  column {
    name = "ACCOUNT_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "INDUSTRY"
    type = "VARCHAR(100)"
  }
  column {
    name = "ANNUAL_REVENUE"
    type = "NUMBER(15,2)"
  }
  column {
    name = "SUBSCRIPTION_START_DATE"
    type = "DATE"
  }
  column {
    name = "SUBSCRIPTION_END_DATE"
    type = "DATE"
  }
  column {
    name = "IS_CHURNED"
    type = "BOOLEAN"
  }
  column {
    name = "TIER"
    type = "VARCHAR(20)"
  }
  column {
    name = "ACCOUNT_OWNER_ID"
    type = "VARCHAR(50)"
  }
}

resource "snowflake_table" "opportunities" {
  database = snowflake_database.prod.name
  schema   = snowflake_schema.b2bsaas.name
  name     = "OPPORTUNITIES"

  column {
    name = "OPPORTUNITY_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "ACCOUNT_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "PRODUCT_CODE"
    type = "VARCHAR(50)"
  }
  column {
    name = "STAGE"
    type = "VARCHAR(20)"
  }
  column {
    name = "AMOUNT_GBP"
    type = "NUMBER(15,2)"
  }
  column {
    name = "CLOSE_DATE"
    type = "DATE"
  }
  column {
    name = "LEAD_SOURCE"
    type = "VARCHAR(50)"
  }
}


#Snowflake tables for the usage and interactions logs

resource "snowflake_table" "usage_logs" {
  database = snowflake_database.prod.name
  schema   = snowflake_schema.b2bsaas.name
  name     = "USAGE_LOGS"

  column {
    name = "SESSION_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "ACCOUNT_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "USER_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "FEATURE_USED"
    type = "VARCHAR(100)"
  }
  column {
    name = "SESSION_DURATION_SECONDS"
    type = "NUMBER(10,0)"
  }
  column {
    name = "ERROR_CODES_ENCOUNTERED"
    type = "VARCHAR(50)"
  }
  column {
    name = "TIMESTAMP"
    type = "TIMESTAMP_NTZ"
  }
}

resource "snowflake_table" "interaction_transcripts" {
  database = snowflake_database.prod.name
  schema   = snowflake_schema.b2bsaas.name
  name     = "INTERACTION_TRANSCRIPTS"

  column {
    name = "INTERACTION_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "ACCOUNT_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "OPPORTUNITY_ID"
    type = "VARCHAR(50)"
  }
  column {
    name = "TIMESTAMP"
    type = "TIMESTAMP_NTZ"
  }
  column {
    name = "INTERACTION_TYPE"
    type = "VARCHAR(30)"
  }
  column {
    name = "TRANSCRIPT_BODY"
    type = "VARCHAR(5000)"
  }
}
