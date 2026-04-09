data "google_compute_network" "vpc" {
  for_each = var.vm_settings

  name    = each.value.network_name
  project = each.value.project_id
}

data "google_compute_subnetwork" "subnet" {
  for_each = var.vm_settings

  name    = each.value.subnetwork_name
  project = each.value.project_id
  region  = each.value.subnetwork_region
}
