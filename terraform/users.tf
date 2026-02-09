resource "snowflake_user" "de_vignesh" {
  name         = "DE_VIGNESH"
  login_name   = "DE_VIGNESH"
  password     = "SamplePassword"
  default_role = snowflake_account_role.admin.name
}

#Sample Users

# resource "snowflake_user" "user_x_sarah" {
#   name         = "user_x"
#   login_name   = "user_x"
#   password     = "samplepassword" -- retrieved from secrets manager in general
#   default_role = snowflake_account_role.read_only.name
# }

# -- Role assignments --

resource "snowflake_grant_account_role" "de_vignesh_admin" {
  role_name = snowflake_account_role.admin.name
  user_name = snowflake_user.de_vignesh.name
}

# resource "snowflake_grant_account_role" "user_x_readonly" {
#   role_name = snowflake_account_role.read_only.name
#   user_name = snowflake_user.user_x.name
# }
