# ============================================================
# Analytics Hub - Data Sources
# ============================================================

data "google_project" "exchange_projects" {
  for_each = {
    for k, v in var.analytics_hub_settings : v.project_id => v
  }
  project_id = each.key
}
