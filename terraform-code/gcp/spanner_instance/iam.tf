# Papéis fixos em nível de instância. Usa google_spanner_instance_iam_binding
# (autoritativo por role) em vez de _iam_member, o que elimina a necessidade
# de flatten: cada resource recebe a lista de membros diretamente do settings.
#
# ATENÇÃO: *_iam_binding é autoritativo — substitui todos os membros daquele
# role naquela instância a cada apply. Se algum dia precisar de bindings
# aditivos (ex: concedidos fora do Terraform), trocar para *_iam_member exige
# voltar ao padrão de flatten (instance x member), igual ao dataplex-iam.

resource "google_spanner_instance_iam_binding" "admin" {
  for_each = {
    for k, v in var.spanner_instance_settings : k => v
    if length(v.iam_bindings.admins) > 0
  }

  project  = each.value.project_id
  instance = google_spanner_instance.this[each.key].name
  role     = "roles/spanner.admin"
  members  = each.value.iam_bindings.admins
}

resource "google_spanner_instance_iam_binding" "database_admin" {
  for_each = {
    for k, v in var.spanner_instance_settings : k => v
    if length(v.iam_bindings.database_admins) > 0
  }

  project  = each.value.project_id
  instance = google_spanner_instance.this[each.key].name
  role     = "roles/spanner.databaseAdmin"
  members  = each.value.iam_bindings.database_admins
}

resource "google_spanner_instance_iam_binding" "viewer" {
  for_each = {
    for k, v in var.spanner_instance_settings : k => v
    if length(v.iam_bindings.viewers) > 0
  }

  project  = each.value.project_id
  instance = google_spanner_instance.this[each.key].name
  role     = "roles/spanner.viewer"
  members  = each.value.iam_bindings.viewers
}
