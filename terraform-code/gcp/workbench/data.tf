data "google_project" "project" {
  for_each = local.unique_projects_flat

  project_id = each.key
}

resource "google_project_service_identity" "notebooks_identity" {
  for_each = local.unique_projects_flat
  provider = google-beta
  project  = each.key
  service  = "notebooks.googleapis.com"
}

resource "google_project_service_identity" "compute_identity" {
  for_each = local.unique_projects_flat

  provider = google-beta
  project  = each.key
  service  = "compute.googleapis.com"
}
