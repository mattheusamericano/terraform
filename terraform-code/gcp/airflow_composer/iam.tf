# --------------------------------------------------------
# IAM Bindings - SA no projeto host (Shared VPC)
# --------------------------------------------------------
resource "google_project_iam_member" "composer_sa_host_network" {
  for_each = var.composer_settings

  project = each.value.network_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.composer_sa[each.key].email}"
}

# --------------------------------------------------------
# IAM Bindings - SA no projeto de serviço
# --------------------------------------------------------
resource "google_project_iam_member" "composer_sa_roles" {
  for_each = {
    for pair in flatten([
      for k, v in var.composer_settings : [
        for role in v.sa_roles : {
          key        = "${k}__${role}"
          env_key    = k
          project_id = v.project_id
          role       = role
          email      = google_service_account.composer_sa[k].email
        }
      ]
    ]) : pair.key => pair
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${each.value.email}"
}

# --------------------------------------------------------
# IAM Binding - Composer Agent no projeto host (Shared VPC)
#
# for_each sobre local.unique_projects_flat (um item por project_id único em
# composer_settings), não sobre var.project_id/var.network_project_id soltos:
# quando dois ambientes Composer estão no mesmo projeto, essas roles do
# Service Agent existem uma única vez no state, compartilhada pelos dois. Se
# um dos ambientes for removido de composer_settings e o outro permanecer no
# mesmo projeto, a chave do projeto continua presente em unique_projects_flat
# e a role NÃO é destruída — só é destruída quando o último ambiente daquele
# projeto sai do mapa.
# --------------------------------------------------------
resource "google_project_iam_member" "composer_agent_host_network" {
  for_each = local.unique_projects_flat

  project = each.key
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.project[each.key].number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "composer_agent_roles" {
  for_each = local.unique_projects_flat

  project = each.key
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${data.google_project.project[each.key].number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "composer_agent_shared_vpc" {
  for_each = local.unique_projects_flat

  project = each.value.network_project_id
  role    = "roles/composer.sharedVpcAgent"
  member  = "serviceAccount:service-${data.google_project.project[each.key].number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

#Permissão de Data Viewer no projeto Big Data "engenharia-bigdata-prd"
resource "google_project_iam_member" "composer_bigquery_viewer" {
  for_each = var.composer_settings

  project = "bigdata-1744049006"
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.composer_sa[each.key].email}"
}

#Permissão de criptografia (KMS) para Service Accounts
resource "google_kms_crypto_key_iam_member" "composer_sa_kms" {
  for_each = local.kms_unique_bindings_flat

  crypto_key_id = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project[each.value.project_id].number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

#Permissão de criptografia (KMS) para Service Accounts
resource "google_kms_crypto_key_iam_member" "composer_bucket_sa_kms" {
  for_each = local.kms_unique_bindings_flat

  crypto_key_id = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project[each.value.project_id].number}@gs-project-accounts.iam.gserviceaccount.com"
}