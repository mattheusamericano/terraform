# ============================================================
# Analytics Hub - Data Exchanges
# ============================================================

resource "google_bigquery_analytics_hub_data_exchange" "exchange" {
  for_each = var.analytics_hub_settings

  project           = "${each.value.project_id}"
  location          = "${each.value.region}"
  data_exchange_id  = "exchange_${replace(each.key, "-", "_")}_${each.value.sigla}_${terraform.workspace}"
  display_name      = "${each.value.display_name}"
  description       = "${each.value.description}"
  discovery_type    = "DISCOVERY_TYPE_PUBLIC"

  sharing_environment_config {
    dynamic "default_exchange_config" {
      for_each = !each.value.is_data_clean_room ? [1] : []
      content {}
    }
    dynamic "dcr_exchange_config" {
      for_each = each.value.is_data_clean_room ? [1] : []
      content {}
    }
  }

}