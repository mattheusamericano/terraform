data "google_project" "project" {
  for_each = local.distinct_projects_with_kms

  project_id = each.key
}

data "google_kms_key_ring" "keyring" {
  for_each = local.distinct_projects_with_kms

  name     = each.value[0].key_ring
  location = each.value[0].region
  project  = each.value[0].kms_project_id
}

data "google_kms_crypto_key" "keycrypto" {
  for_each = local.distinct_projects_with_kms

  name      = each.value[0].key_crypto
  key_ring = data.google_kms_key_ring.keyring[each.key].id
}