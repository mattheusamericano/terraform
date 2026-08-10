resource "google_sql_database" "databases" {
  for_each = var.cloud_sql_database_settings

  name        = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  instance    = data.google_sql_database_instance.instance[each.key].name
  project     = each.value["project_id"]
}