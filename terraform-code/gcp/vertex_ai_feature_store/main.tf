resource "google_ai_platform_featurestore" "featurestore" {
  for_each = var.feature_store_settings
  project = each.value.project_id
  region = each.value.region
  name = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  online_serving_config { fixed_node_count = 1 }
  encryption_spec { kms_key_name = "projects/${each.value.kms_project_id}/locations/${each.value.region}/keyRings/${each.value.key_ring}/cryptoKeys/${each.value.key_crypto}" }
  labels = each.value.labels
  depends_on = [google_kms_crypto_key_iam_member.featurestore_kms]
}
