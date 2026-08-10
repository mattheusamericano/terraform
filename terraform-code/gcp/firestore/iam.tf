# ============================================================
# IAM - Firestore Database Module
# ============================================================

# KMS - permissão para o service account do Firestore
resource "google_kms_crypto_key_iam_member" "firestore_sa_kms" {
  for_each = {
    for k, v in var.firestore_settings : k => v
    if v.kms_keyring != null
  }

  crypto_key_id = data.google_kms_crypto_key.firestore_key[each.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project[each.key].number}@gcp-sa-firestore.iam.gserviceaccount.com"

}

# Permissão de escrita no database
resource "google_project_iam_member" "firestore_writer" {
  for_each = var.firestore_settings

  project  = each.value.project_id
  role     = "roles/datastore.user"
  member   = "group:${each.value.group_writer}"
}

# Permissão de leitura no database
resource "google_project_iam_member" "reader" {
  for_each = {
    for k, v in var.firestore_settings : k => v
    if v.group_reader != null
  }

  project  = each.value.project_id
  role     = "roles/datastore.viewer"
  member   = "group:${each.value.group_reader}"
}