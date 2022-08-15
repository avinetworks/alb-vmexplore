resource "random_string" "password" {
  length           = 8
  special          = true
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "_"
}