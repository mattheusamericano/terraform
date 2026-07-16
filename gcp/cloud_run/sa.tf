resource "google_service_account" "cloudrun_sa" {
  for_each = var.cloud_run_settings

  account_id   = each.value.sa_account_id
  display_name = "Service Account Cloud Run - Terraform"
  project      = each.value.project_id
}