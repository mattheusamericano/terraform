resource "google_cloudbuild_worker_pool" "this" {
  for_each = var.worker_pool_settings

  name     = "${each.key}_${each.value.sigla}_${terraform.workspace}"
  project  = each.value.project_id
  location = each.value.location

  annotations = each.value.annotations

  worker_config {
    machine_type   = each.value.machine_type
    disk_size_gb   = each.value.disk_size_gb
    no_external_ip = each.value.no_external_ip
  }

  network_config {
    peered_network          = "projects/${each.value.network_project_id}/global/networks/${each.value.network_name}"
    peered_network_ip_range = each.value.peered_network_ip_range
  }
}
