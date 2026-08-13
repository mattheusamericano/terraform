# IAM aditivo: concede roles/cloudbuild.workerPoolUser aos principals informados em
# worker_pool_users, permitindo o uso do pool a partir de outros projetos/pipelines.
# Aditivo porque o consumo do pool é feito por identidades externas ao módulo, não
# pelo owner do recurso.
#
# O provider google não expõe um resource `google_cloudbuild_worker_pool_iam_member`
# (Cloud Build não publica IAM policy por worker pool via API/Terraform). A concessão
# oficial do `roles/cloudbuild.workerPoolUser` é feita via `google_project_iam_member`
# no projeto do pool. Usamos uma IAM Condition com `resource.name` para restringir o
# binding ao worker pool específico, evitando conceder acesso a todos os pools do projeto.
resource "google_project_iam_member" "worker_pool_user" {
  for_each = local.worker_pool_user_bindings

  project = google_cloudbuild_worker_pool.this[each.value.key].project
  role    = "roles/cloudbuild.workerPoolUser"
  member  = each.value.member

  condition {
    title       = "restrict-to-${each.value.key}"
    description = "Restringe roles/cloudbuild.workerPoolUser ao worker pool ${each.value.key}"
    expression  = "resource.name == \"${google_cloudbuild_worker_pool.this[each.value.key].id}\""
  }
}

# IAM aditivo: concede à SA do Cloud Build as roles listadas em
# worker_pool_settings.*.service_account.roles, no escopo do projeto do pool. Aditivo
# porque essas roles vivem em recursos (BigQuery, GCS, Artifact Registry etc.) que não
# são owned por este módulo.
resource "google_project_iam_member" "cloudbuild_sa_roles" {
  for_each = local.cloudbuild_sa_role_bindings

  project = each.value.project
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.cloudbuild[each.value.key].email}"
}