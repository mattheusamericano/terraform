data "google_project" "project" {
  for_each = toset([for value in var.colab_runtime_template_settings : value.project_id])

  project_id = each.key
}
