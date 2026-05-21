 # Deduplica por project_id
locals {
  distinct_projects_with_kms = {
    for k, v in var.bq_dataset_settings :
    v.project_id => v
    if v.kms_key != null
  }
}

# Permissão de criptografia (KMS) para Service Account do BigQuery
resource "google_kms_crypto_key_iam_member" "bq_sa_kms" {
  for_each = local.distinct_projects_with_kms

  crypto_key_id = data.google_kms_crypto_key.keycrypto[each.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${data.google_project.project[each.key].number}@bigquery-encryption.iam.gserviceaccount.com"

}
# Permissão para OWNER do recurso Dataset ao SA
resource "google_bigquery_dataset_iam_member" "access_owner" {
  for_each = var.bq_dataset_settings

  dataset_id    = google_bigquery_dataset.dataset[each.key].dataset_id
  project       = each.value.project_id
  role          = "roles/bigquery.dataOwner"
  member        = "serviceAccount:${google_service_account.bq_dataset_sa[each.key].email}"
}
# Permissão para WRITER do recurso Dataset ao GRUPO DE ACESSO
resource "google_bigquery_dataset_iam_member" "access_writer" {
  for_each = var.bq_dataset_settings

  dataset_id    = google_bigquery_dataset.dataset[each.key].dataset_id
  project       = each.value.project_id
  role          = "roles/bigquery.dataEditor"
  member        = "group:${each.value.group_writer}"
}

 #Permissão de Data Viewer no projeto Big Data "engenharia-bigdata-prd"
 resource "google_project_iam_member" "bigquery_viewer" {
  for_each   = var.bq_dataset_settings

  project         = "bigdata-1744049006"
  role            = "roles/bigquery.dataViewer"
  member          = "serviceAccount:${google_service_account.bq_dataset_sa[each.key].email}"
 }
