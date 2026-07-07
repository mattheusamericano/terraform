resource "google_spanner_database" "this" {
  for_each = var.spanner_database_settings

  project                  = each.value.project_id
  instance                 = each.value.instance_name
  name                     = "${each.key}_${each.value.sigla}_${terraform.workspace}"
  database_dialect         = each.value.database_dialect
  ddl                      = each.value.ddl
  deletion_protection      = each.value.deletion_protection
  version_retention_period = each.value.version_retention_period
}
