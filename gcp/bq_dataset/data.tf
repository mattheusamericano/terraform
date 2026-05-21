data "google_project" "project" {
  for_each = var.bq_dataset_settings

  project_id = each.value.project_id
}

data "google_kms_key_ring" "keyring" {
  for_each = {
    for k, v in var.bq_dataset_settings :
    k => v
    if v.kms_key != null
  }

  name     = each.value.key_ring
  location = each.value.region
  project  = each.value.kms_project_id
}

data "google_kms_crypto_key" "keycrypto" {
  for_each = {
    for k, v in var.bq_dataset_settings :
    k => v
    if v.kms_key != null
  }

  name      = each.value.key_crypto
  key_ring = data.google_kms_key_ring.keyring[each.key].id
}