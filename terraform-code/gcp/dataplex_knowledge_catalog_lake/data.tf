# ============================================================
# Dataplex - Data Sources
# ============================================================

data "google_project" "lake_projects" {
  for_each = {
    for k, v in var.dataplex_lake_settings: v.project_id => v
  }
  project_id = each.key
}
