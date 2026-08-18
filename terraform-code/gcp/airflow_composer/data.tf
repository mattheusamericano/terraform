# ============================================================
# Cloud Composer 3 - Data Sources
# ============================================================

data "google_kms_key_ring" "composer" {
  for_each = var.composer_settings

  name     = each.value.key_ring
  location = each.value.region
  project  = each.value.kms_project_id
}

data "google_kms_crypto_key" "composer" {
  for_each = var.composer_settings

  name     = each.value.key_crypto
  key_ring = data.google_kms_key_ring.composer[each.key].id
}

data "google_project" "project" {
  for_each = local.unique_projects_flat

  project_id = each.key
}