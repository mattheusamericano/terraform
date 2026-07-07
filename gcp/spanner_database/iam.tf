# Mesmo padrão do spanner-instance/iam.tf: bindings fixos por role,
# autoritativos, sem flatten — o for_each roda sobre o próprio settings.

resource "google_spanner_database_iam_binding" "database_admin" {
  for_each = {
    for k, v in var.spanner_database_settings : k => v
    if length(v.iam_bindings.database_admins) > 0
  }

  project  = each.value.project_id
  instance = each.value.instance_name
  database = google_spanner_database.this[each.key].name
  role     = "roles/spanner.databaseAdmin"
  members  = each.value.iam_bindings.database_admins
}

resource "google_spanner_database_iam_binding" "database_user" {
  for_each = {
    for k, v in var.spanner_database_settings : k => v
    if length(v.iam_bindings.database_users) > 0
  }

  project  = each.value.project_id
  instance = each.value.instance_name
  database = google_spanner_database.this[each.key].name
  role     = "roles/spanner.databaseUser"
  members  = each.value.iam_bindings.database_users
}

resource "google_spanner_database_iam_binding" "database_reader" {
  for_each = {
    for k, v in var.spanner_database_settings : k => v
    if length(v.iam_bindings.database_readers) > 0
  }

  project  = each.value.project_id
  instance = each.value.instance_name
  database = google_spanner_database.this[each.key].name
  role     = "roles/spanner.databaseReader"
  members  = each.value.iam_bindings.database_readers
}
