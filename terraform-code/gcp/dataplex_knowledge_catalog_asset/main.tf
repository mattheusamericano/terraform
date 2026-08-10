# ============================================================
# Dataplex Asset (BigQuery dataset ou GCS bucket)
# ============================================================

resource "google_dataplex_asset" "asset" {
  for_each = var.dataplex_asset_settings

  project       = "${each.value.project_id}"
  location      = "${each.value.region}"
  lake          = "${each.value.lake_key}"
  dataplex_zone = "${each.value.zone_key}"
  labels        = each.value["labels"]

  name         = "asset-${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name = "Asset ${upper(replace(each.key, "-", " "))}"
  description  = "${each.value.asset_description}"

  resource_spec {
    name = "${each.value.resource_name}"
    type = "${each.value.resource_type}"
  }

  discovery_spec {
    enabled  = "${each.value.discovery_enabled}"
    schedule = "${each.value.discovery_schedule}"
  }
}
