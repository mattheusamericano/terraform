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
