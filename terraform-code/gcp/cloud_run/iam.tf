# Artifact Registry
resource "google_project_iam_member" "artifact_registry_reader" {
  for_each = var.cloud_run_settings

  project = each.value.project_id
  role    = "roles/artifactregistry.reader"
  member  = google_service_account.cloudrun_sa[each.key].member
}

# Logging
resource "google_project_iam_member" "log_writer" {
  for_each = var.cloud_run_settings

  project = each.value.project_id
  role    = "roles/logging.logWriter"
  member  = google_service_account.cloudrun_sa[each.key].member
}

# Monitoring
resource "google_project_iam_member" "monitoring_writer" {
  for_each = var.cloud_run_settings

  project = each.value.project_id
  role    = "roles/monitoring.metricWriter"
  member  = google_service_account.cloudrun_sa[each.key].member
}
resource "google_compute_subnetwork_iam_member" "cloudrun_network_user" {
  for_each = {
    for k, v in var.cloud_run_settings :
    k => v if try(v.vpc_connector, null) != null
  }

  project    = each.value.network_project_id
  region     = each.value.region
  subnetwork = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"

  role   = "roles/compute.networkUser"
  member = google_service_account.cloudrun_sa[each.key].member
}