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