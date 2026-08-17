# IAM aditivo: concede a cada SA as roles listadas em sa_settings.*.roles, no
# project_id da própria SA. Aditivo (google_project_iam_member) porque essas roles
# vivem em recursos (BigQuery, GCS, Pub/Sub etc.) que não são owned por este módulo.
#
# Para conceder role em projeto diferente do project_id da SA, ou para bindings
# autoritativos/custom roles, use o módulo iam_new.
resource "google_project_iam_member" "sa_roles" {
  for_each = local.sa_role_bindings

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.sa[each.value.key].email}"
}
