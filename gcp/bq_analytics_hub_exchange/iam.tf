# ============================================================
# Analytics Hub - IAM
# ============================================================

# IAM no Exchange — publishers, subscribers e admins

resource "google_bigquery_analytics_hub_data_exchange_iam_member" "admin" {
    for_each = var.analytics_hub_settings

    project             = each.value.project_id
    location            = each.value.region
    data_exchange_id    = google_bigquery_analytics_hub_data_exchange.exchange[each.key].data_exchange_id
    role                = "roles/analyticshub.admin"
    member              = "group:${each.value.iam_groups.admin}"
}