# ============================================================
# Data Sources - GKE Cluster Module
# ============================================================

data "google_project" "project" {
  for_each = var.gke_cluster_settings

  project_id = each.value.project_id
}

data "google_compute_network" "vpc" {
  for_each = var.gke_cluster_settings

  name    = each.value.name_vpc_shared
  project = each.value.network_project_id
}

data "google_compute_subnetwork" "subnet" {
  for_each = var.gke_cluster_settings

  name    = each.value.subnet_name
  region  = each.value.region
  project = each.value.network_project_id
}

# KMS - apenas clusters com criptografia configurada
data "google_kms_key_ring" "keyring" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.kms_keyring_name != null
  }

  name     = each.value.kms_keyring_name
  location = each.value.region
  project  = each.value.kms_project_id
}

data "google_kms_crypto_key" "gke_key" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.kms_key_name != null
  }

  name     = each.value.kms_key_name
  key_ring = data.google_kms_key_ring.keyring[each.key].id
}
