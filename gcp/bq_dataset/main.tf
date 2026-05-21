resource "google_bigquery_dataset" "dataset" {
  for_each = var.bq_dataset_settings

  dataset_id = "${each.key}_${each.value.sigla}_${terraform.workspace}"
  location   = each.value.region
  project    = each.value.project_id

  friendly_name                   = "${each.key}_${each.value.sigla}_${terraform.workspace}"
  description                     = each.value.description
  delete_contents_on_destroy      = true
  default_partition_expiration_ms = each.value.default_partition_expiration_ms
  default_table_expiration_ms     = each.value.default_table_expiration_ms

  labels = each.value.labels

  dynamic "default_encryption_configuration" {
    for_each = each.value.kms_key != null ? [1] : []
    content {
      kms_key_name = each.value.kms_key
    }
  }
}