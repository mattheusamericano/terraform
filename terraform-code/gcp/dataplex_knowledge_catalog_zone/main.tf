# ============================================================
# Dataplex Zone (RAW ou CURATED)
# ============================================================

resource "google_dataplex_zone" "zone" {
  for_each = var.dataplex_zone_settings

  project  = "${each.value.project_id}"
  location = "${each.value.region}"
  lake     = "${each.value.lake_key}"

  name         = "zone-${lower(each.value.zone_type)}-${each.key}"
  display_name = "Zone ${upper(each.value.zone_type)} - ${upper(each.key)}"
  type         = "${each.value.zone_type}"
  labels        = each.value["labels"]

  resource_spec {
    location_type = "${each.value.location_type}"
  }

  discovery_spec {
    enabled  = "${each.value.discovery_enabled}"
    schedule = "${each.value.discovery_schedule}"

    dynamic "csv_options" {
      for_each = each.value.csv_delimiter != null ? [each.value.csv_delimiter] : []
      content {
        delimiter = csv_options.value
      }
    }
  }
}
