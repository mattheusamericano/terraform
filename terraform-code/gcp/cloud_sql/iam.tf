resource "google_service_account" "sql_proxy_sa" {
  for_each = var.cloud_sql_instance_settings

  account_id    = "${each.key}-${each.value.sigla}-${terraform.workspace}-sql-proxy"
  display_name  = "Cloud SQL Proxy SA - ${each.key}-${each.value.sigla}-${terraform.workspace}"
  project       = each.value["project_id"]
}

resource "google_project_iam_member" "sql_client" {
  for_each = var.cloud_sql_instance_settings

  project       = each.value["project_id"]
  role          = "roles/cloudsql.client"
  member        = "serviceAccount:${google_service_account.sql_proxy_sa[each.key].email}"
}

resource "google_project_iam_member" "group_users_client" {
  for_each = var.cloud_sql_instance_settings

  project       = each.value["project_id"]
  role          = "roles/cloudsql.client"
  member        = "group:${each.value.group_users}"
}

 #Permissão de criptografia (KMS) para Service Agent Notebook 
 resource "google_kms_crypto_key_iam_member" "sql_kms" {
     for_each = var.cloud_sql_instance_settings

     crypto_key_id               = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
     role                        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
     member                      = "serviceAccount:${google_service_account.sql_proxy_sa[each.key].email}"
 }