resource "snowflake_account_role" "admin" {
  name = "VANTAGEPOINT_ADMIN"
}

resource "snowflake_account_role" "read_only" {
  name = "VANTAGEPOINT_READ_ONLY"
}

# -- Admin: warehouse --

resource "snowflake_grant_privileges_to_account_role" "admin_wh" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "OPERATE", "MODIFY", "MONITOR"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.vantagepoint.name
  }
}

# -- Admin: database --

resource "snowflake_grant_privileges_to_account_role" "admin_db" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "CREATE SCHEMA", "MONITOR"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.prod.name
  }
}

# -- Admin: schema --

resource "snowflake_grant_privileges_to_account_role" "admin_schema" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "CREATE PIPE", "CREATE TASK", "CREATE FUNCTION", "CREATE PROCEDURE"]
  on_schema {
    schema_name = "\"${snowflake_database.prod.name}\".\"${snowflake_schema.b2bsaas.name}\""
  }
}

# -- Admin: tables --

resource "snowflake_grant_privileges_to_account_role" "admin_tables" {
  account_role_name = snowflake_account_role.admin.name
  privileges        = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.prod.name}\".\"${snowflake_schema.b2bsaas.name}\""
    }
  }
}

# -- Read Only: warehouse --

resource "snowflake_grant_privileges_to_account_role" "read_only_wh" {
  account_role_name = snowflake_account_role.read_only.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.vantagepoint.name
  }
}

# -- Read Only: database --

resource "snowflake_grant_privileges_to_account_role" "read_only_db" {
  account_role_name = snowflake_account_role.read_only.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.prod.name
  }
}

# -- Read Only: schema --

resource "snowflake_grant_privileges_to_account_role" "read_only_schema" {
  account_role_name = snowflake_account_role.read_only.name
  privileges        = ["USAGE"]
  on_schema {
    schema_name = "\"${snowflake_database.prod.name}\".\"${snowflake_schema.b2bsaas.name}\""
  }
}

# -- Read Only: tables --

resource "snowflake_grant_privileges_to_account_role" "read_only_tables" {
  account_role_name = snowflake_account_role.read_only.name
  privileges        = ["SELECT"]
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.prod.name}\".\"${snowflake_schema.b2bsaas.name}\""
    }
  }
}
