resource "google_kms_crypto_key_iam_member" "gcs_kms_binding" {
    for_each = var.bucket_settings

    crypto_key_id   = "${each.value.kms_project_id}/${each.value.region}/${each.value.kms_key_name}/${each.value.kms_key_crypto}"
    role            = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    member          = "serviceAccount:${data.google_storage_project_service_account.gcs_sa[each.key].email_address}"
}