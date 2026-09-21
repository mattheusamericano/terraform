resource "google_project_service_identity" "pubsub" {
  for_each = local.pubsub_cmek_projects

  provider = google-beta
  project  = each.key
  service  = "pubsub.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "pubsub" {
  for_each = local.pubsub_cmek_bindings

  crypto_key_id = each.value.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.pubsub[each.value.project_id].email}"
}
