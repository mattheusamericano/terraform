# IAM aditivo: concede a cada SA as roles listadas em sa_settings.*.roles, no
# project_id da própria SA. Aditivo (google_project_iam_member) porque essas roles
# vivem em recursos (BigQuery, GCS, Pub/Sub etc.) que não são owned por este módulo.
resource "google_project_iam_member" "sa_roles" {
  for_each = local.sa_role_bindings

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.sa[each.value.key].email}"
}

# IAM aditivo cross-project: concede a cada SA as roles listadas em
# sa_settings.*.cross_project_roles, cada uma no project_id informado NA PRÓPRIA
# entrada (não no project_id da SA). Um resource por combinação SA+projeto+role.
resource "google_project_iam_member" "sa_cross_project_roles" {
  for_each = local.sa_cross_project_role_bindings

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.sa[each.value.key].email}"
}
