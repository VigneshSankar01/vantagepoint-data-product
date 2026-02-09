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
