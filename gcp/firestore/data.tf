# ============================================================
# Data Sources - Firestore Module
# ============================================================

data "google_project" "project" {
  for_each = var.firestore_settings

  project_id = each.value.project_id
}

# KMS - apenas para databases com criptografia configurada
data "google_kms_key_ring" "keyring" {
  for_each = {
    for k, v in var.firestore_settings : k => v
    if v.kms_keyring_name != null
  }

  name     = each.value.kms_keyring_name
  location = each.value.region
  project  = each.value.kms_project_id
}

data "google_kms_crypto_key" "firestore_key" {
  for_each = {
    for k, v in var.firestore_settings : k => v
    if v.kms_key_name != null
  }

  name     = each.value.kms_key_name
  key_ring = data.google_kms_key_ring.keyring[each.key].id
}
