resource "google_project_service_identity" "artifact_registry" {
  for_each = local.artifact_registry_cmek_projects

  provider = google-beta
  project  = each.key
  service  = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "artifact_registry" {
  for_each = local.artifact_registry_cmek_bindings

  crypto_key_id = each.value.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.artifact_registry[each.value.project_id].email}"
}
