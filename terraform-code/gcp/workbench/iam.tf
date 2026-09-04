# Todas as roles da SA no próprio projeto em um único recurso
resource "google_project_iam_member" "workbench_sa_own_project_roles" {
  for_each = local.sa_own_project_iam_bindings

  project = each.value.project
  role    = each.value.role
  member  = google_service_account.workbench_sa[each.value.wb_key].member
}

# Roles cross-project da SA de cada Workbench, definidas em
# workbench_settings.<chave>.cross_project_roles — zero, uma ou várias por
# Workbench, cada uma em um projeto diferente do project_id da própria SA.
resource "google_project_iam_member" "workbench_sa_cross_project_roles" {
  for_each = local.sa_cross_project_iam_bindings

  project = each.value.project_id
  role    = each.value.role
  member  = google_service_account.workbench_sa[each.value.wb_key].member
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
