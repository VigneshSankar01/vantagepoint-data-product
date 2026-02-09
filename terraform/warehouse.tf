resource "snowflake_warehouse" "vantagepoint" {
  name           = "VANTAGEPOINT_WH"
  warehouse_size = "XSMALL"
  auto_suspend   = 60
  auto_resume    = true
}

resource "snowflake_database" "prod" {
  name = "VANTAGEPOINT_PROD"
}

resource "snowflake_schema" "b2bsaas" {
  database = snowflake_database.prod.name
  name     = "B2BSAAS"
}
