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

resource "google_project_iam_member" "cloudbuild_sa_roles" {
  for_each = local.cloudbuild_sa_role_bindings

  project = each.value.project
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.cloudbuild[each.value.key].email}"
}

resource "google_kms_crypto_key_iam_member" "cloudbuild_bucket" {
  for_each = local.cloudbuild_bucket_cmek

  crypto_key_id = each.value
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.cloudbuild_bucket[each.key].email_address}"
}
