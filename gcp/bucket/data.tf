data "google_storage_project_service_account" "gcs_sa" {
    for_each = var.bucket_settings
    project  = each.value["project_id"]
}