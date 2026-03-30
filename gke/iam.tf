# ============================================================
# IAM - GKE Cluster Module
# ============================================================

# Service Account dedicada para os nodes do GKE
resource "google_service_account" "gke_sa" {
  for_each = var.gke_cluster_settings

  account_id   = "sa-gke-${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name = "SA GKE - ${each.key} - ${each.value.sigla} - ${terraform.workspace}"
  project      = each.value.project_id
}

# Roles mínimas necessárias para os nodes (princípio least privilege)
locals {
  gke_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader",
    "roles/storage.objectViewer",
  ]

  gke_sa_role_bindings = flatten([
    for k, v in var.gke_cluster_settings : [
      for role in local.gke_sa_roles : {
        key        = "${k}-${role}"
        project_id = v.project_id
        cluster_key = k
        role       = role
      }
    ]
  ])
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = {
    for binding in local.gke_sa_role_bindings : binding.key => binding
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.gke_sa[each.value.cluster_key].email}"
}

# KMS - permissão para o SA do GKE na chave
resource "google_kms_crypto_key_iam_member" "gke_sa_kms" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.kms_key_name != null
  }

  crypto_key_id = data.google_kms_crypto_key.gke_key[each.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project[each.key].number}@container-engine-robot.iam.gserviceaccount.com"

  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================
# IAM - Cloud Service Mesh (Fleet SA permissions)
# Necessário para MANAGEMENT_AUTOMATIC funcionar
# ============================================================

# SA do Fleet Hub
locals {
  fleet_sa = {
    for k, v in var.gke_cluster_settings : k =>
      "serviceAccount:service-${data.google_project.project[k].number}@gcp-sa-gkehub.iam.gserviceaccount.com"
    if v.enable_service_mesh
  }
}

# Permissão no projeto do cluster
resource "google_project_iam_member" "fleet_sa_container_admin" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.enable_service_mesh
  }

  project = each.value.project_id
  role    = "roles/container.admin"
  member  = local.fleet_sa[each.key]
}

# Permissão para acessar recursos do Fleet
resource "google_project_iam_member" "fleet_sa_gkehub_agent" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.enable_service_mesh
  }

  project = each.value.project_id
  role    = "roles/gkehub.serviceAgent"
  member  = local.fleet_sa[each.key]
}

# Permissão no host project da Shared VPC
resource "google_project_iam_member" "fleet_sa_network_viewer" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.enable_service_mesh
  }

  project = each.value.network_project_id  # host project
  role    = "roles/compute.networkViewer"
  member  = local.fleet_sa[each.key]
}

# Permissão do SA do mesh no projeto do cluster
resource "google_project_iam_member" "mesh_sa_service_agent" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.enable_service_mesh
  }

  project = each.value.project_id
  role    = "roles/meshconfig.admin"
  member  = local.fleet_sa[each.key]
}
