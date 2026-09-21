data "google_storage_project_service_account" "cloudbuild_bucket" {
  for_each = local.cloudbuild_bucket_cmek

  project = each.key
}
