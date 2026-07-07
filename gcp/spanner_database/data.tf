data "google_project" "spanner_project" {
  for_each   = var.spanner_database_settings
  project_id = each.value.project_id
}
