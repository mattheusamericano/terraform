resource "google_storage_bucket" "cloudbuild_default" {
  for_each = local.cloudbuild_default_buckets

  name                        = "${each.key}_cloudbuild"
  project                     = each.key
  location                    = each.value.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  dynamic "encryption" {
    for_each = each.value.kms_key_name != null ? [each.value.kms_key_name] : []
    content {
      default_kms_key_name = encryption.value
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.cloudbuild_bucket]
}
