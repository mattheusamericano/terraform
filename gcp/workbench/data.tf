locals {
  unique_projects = {
    for k, v in var.workbench_settings :
    v.project_id => v...
  }

  unique_projects_flat = {
    for key, val in local.unique_projects :
    key => val[0]
  }
}

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
 