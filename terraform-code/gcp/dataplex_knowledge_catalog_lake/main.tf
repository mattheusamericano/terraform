# ============================================================
# Dataplex Lake
# ============================================================

resource "google_dataplex_lake" "lake" {
  for_each = var.dataplex_lake_settings

  project       = "${each.value.project_id}"
  location      = "${each.value.region}"
  name          = "lake-${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name  = "Lake ${upper(each.key)} ${upper(each.value.sigla)} ${upper(terraform.workspace)}"
  description   = "${each.value.lake_description}"

  labels        = each.value["labels"]

  dynamic "metastore" {
    for_each = each.value.metastore_service != null ? [each.value.metastore_service] : []
    content {
      service = metastore.value
    }
  }
}
