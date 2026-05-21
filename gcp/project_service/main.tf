resource "google_project_service" "project" {
  for_each = toset(var.apis_list)

  project               = var.project_id
  service               = each.value


  disable_on_destroy = false
}