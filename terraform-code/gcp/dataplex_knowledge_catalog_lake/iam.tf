# ============================================================
# Dataplex - IAM
# ============================================================
# Roles fixas por lake: admin, editor, viewer
# admin é obrigatório; editor e viewer são opcionais (null = não provisiona)
# ============================================================

resource "google_dataplex_lake_iam_member" "admin" {
  for_each = var.dataplex_lake_settings

  project  = each.value.project_id
  location = each.value.region
  lake     = google_dataplex_lake.lake[each.key].name
  role     = "roles/dataplex.admin"
  member   = "group:${each.value.iam_groups.admin}"
}

resource "google_dataplex_lake_iam_member" "editor" {
  for_each = {
    for k, v in var.dataplex_lake_settings : k => v
    if v.iam_groups.editor != null
  }

  project  = each.value.project_id
  location = each.value.region
  lake     = google_dataplex_lake.lake[each.key].name
  role     = "roles/dataplex.editor"
  member   = "group:${each.value.iam_groups.editor}"
}

resource "google_dataplex_lake_iam_member" "viewer" {
  for_each = {
    for k, v in var.dataplex_lake_settings : k => v
    if v.iam_groups.viewer != null
  }

  project  = each.value.project_id
  location = each.value.region
  lake     = google_dataplex_lake.lake[each.key].name
  role     = "roles/dataplex.viewer"
  member   = "group:${each.value.iam_groups.viewer}"
}
