locals {
  kms_unique_bindings = {
    for k, v in var.workbench_settings :
    "${v.project_id}||${v.kms_project_id}||${v.region}||${v.key_ring}||${v.key_crypto}" => v...
  }

  kms_unique_bindings_flat = {
    for key, val in local.kms_unique_bindings :
    key => val[0]
  }

  network_unique_bindings = {
    for k, v in var.workbench_settings :
    "${v.network_project_id}||${v.region}||${v.name_subnet_vpc_shared}" => v...
  }

  network_unique_bindings_flat = {
    for key, val in local.network_unique_bindings :
    key => val[0]
  }

  _sa_base_project_roles = [
    "roles/artifactregistry.writer",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/bigquery.user",
    "roles/storage.objectUser",
    "roles/osconfig.projectFeatureSettingsViewer",
    "roles/aiplatform.user",
    "roles/run.developer",
    "roles/logging.logWriter",
    "roles/serviceusage.serviceUsageViewer",
    "roles/dataproc.editor",
    "roles/dataproc.worker",
  ]

  sa_own_project_iam_bindings = {
    for pair in flatten([
      for wb_key, wb in var.workbench_settings : [
        for role in concat(local._sa_base_project_roles, wb.extra_project_roles) : {
          key     = "${wb_key}||${role}"
          project = wb.project_id
          role    = role
          wb_key  = wb_key
        }
      ]
    ]) : pair.key => pair
  }
}

# Todas as roles da SA no próprio projeto em um único recurso
resource "google_project_iam_member" "workbench_sa_own_project_roles" {
  for_each = local.sa_own_project_iam_bindings

  project = each.value.project
  role    = each.value.role
  member  = google_service_account.workbench_sa[each.value.wb_key].member
}

#Permissão de Data Viewer no projeto Big Data "engenharia-bigdata-prd"
resource "google_project_iam_member" "workbench_bigquery_viewer" {
  for_each = var.workbench_settings

  project = "bigdata-1744049006"
  role    = "roles/bigquery.dataViewer"
  member  = google_service_account.workbench_sa[each.key].member
}

#Permissão de criptografia (KMS) para Service Accounts
resource "google_kms_crypto_key_iam_member" "workbench_kms" {
  for_each = var.workbench_settings

  crypto_key_id = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = google_service_account.workbench_sa[each.key].member
}

#Permissão de criptografia (KMS) para Service Agent Notebook
resource "google_kms_crypto_key_iam_member" "workbench_kms_notebook" {
  for_each = local.kms_unique_bindings_flat

  crypto_key_id = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.notebooks_identity[each.value.project_id].email}"
}

#Permissão de criptografia (KMS) para Service Agent Compute
resource "google_kms_crypto_key_iam_member" "workbench_kms_compute" {
  for_each = local.kms_unique_bindings_flat

  crypto_key_id = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project[each.value.project_id].number}@compute-system.iam.gserviceaccount.com"
}

#Permissão para sub-rede do projeto de infra compartilhado
resource "google_compute_subnetwork_iam_member" "ai-service-agent-role-network" {
  for_each = var.workbench_settings

  project    = each.value.network_project_id
  role       = "roles/compute.networkUser"
  region     = each.value.region
  subnetwork = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
  member     = google_service_account.workbench_sa[each.key].member
  depends_on = [google_service_account.workbench_sa]
}

#Permissão para sub-rede do projeto de infra compartilhado para Service Agent
resource "google_compute_subnetwork_iam_member" "ai-service-agent-role-network-svc-agent" {
  for_each = local.network_unique_bindings_flat

  project    = each.value.network_project_id
  role       = "roles/compute.networkUser"
  region     = each.value.region
  subnetwork = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
  member     = "serviceAccount:${google_project_service_identity.notebooks_identity[each.value.project_id].email}"
  depends_on = [google_service_account.workbench_sa]
}
