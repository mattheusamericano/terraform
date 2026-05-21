data "google_project" "project" {
  for_each = var.dataform_repository_settings

  project_id = each.value.project_id
}
