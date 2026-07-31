# IAM aditivo: concede roles/cloudbuild.workerPoolUser aos principals informados em
# worker_pool_users, permitindo o uso do pool a partir de outros projetos/pipelines
# (ex.: service account do Cloud Build em prj-spoke-modelagem). Aditivo porque o
# consumo do pool é feito por identidades externas ao módulo, não pelo owner do recurso.
resource "google_cloudbuild_worker_pool_iam_member" "worker_pool_user" {
  for_each = local.worker_pool_user_bindings

  project     = google_cloudbuild_worker_pool.this[each.value.key].project
  location    = google_cloudbuild_worker_pool.this[each.value.key].location
  worker_pool = google_cloudbuild_worker_pool.this[each.value.key].name
  role        = "roles/cloudbuild.workerPoolUser"
  member      = each.value.member
}
