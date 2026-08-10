resource "google_kms_crypto_key_iam_member" "featurestore_kms" {
  for_each = var.feature_store_settings
  crypto_key_id = "projects/${each.value.kms_project_id}/locations/${each.value.region}/keyRings/${each.value.key_ring}/cryptoKeys/${each.value.key_crypto}"
  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member = "serviceAccount:service-${data.google_project.project[each.key].number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}
