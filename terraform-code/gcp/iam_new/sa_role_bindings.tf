resource "google_project_iam_member" "sa_role_bindings" {
  for_each = var.sa_role_bindings

  project = var.project_id
  role    = startswith(each.value.role, "custom:") ? local.custom_role_lookup[each.value.role] : each.value.role
  member  = "serviceAccount:${google_service_account.sa[each.value.sa_key].email}"
}
