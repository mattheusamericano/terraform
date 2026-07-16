data "google_project" "project" {
  for_each = var.feature_store_settings
  project_id = each.value.project_id
}
