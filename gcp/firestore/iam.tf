# ============================================================
# IAM - Firestore Database Module
# ============================================================

# KMS - permissão para o service account do Firestore
resource "google_kms_crypto_key_iam_member" "firestore_sa_kms" {
  for_each = {
    for k, v in var.firestore_settings : k => v
    if v.kms_key_name != null
  }

  crypto_key_id = data.google_kms_crypto_key.firestore_key[each.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project[each.key].number}@gcp-sa-firestore.iam.gserviceaccount.com"

  lifecycle {
    prevent_destroy = true
  }
}

# Writer - sempre um grupo por database
resource "google_firestore_database_iam_member" "writer" {
  for_each = var.firestore_settings

  project  = each.value.project_id
  database = google_firestore_database.database[each.key].name
  role     = "roles/datastore.user"
  member   = "group:${each.value.group_writer}"
}

# Readers - lista de grupos
resource "google_firestore_database_iam_member" "reader" {
  for_each = {
    for entry in flatten([
      for k, v in var.firestore_settings : [
        for g in v.groups_reader : {
          key         = "${k}-${g}"
          database_key = k
          project_id  = v.project_id
          group       = g
        }
      ]
    ]) : entry.key => entry
  }

  project  = each.value.project_id
  database = google_firestore_database.database[each.value.database_key].name
  role     = "roles/datastore.viewer"
  member   = "group:${each.value.group}"
}
