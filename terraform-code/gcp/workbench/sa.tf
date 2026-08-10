resource "google_service_account" "workbench_sa" {
  for_each = var.workbench_settings

  account_id   = each.value.sa_account_id
  display_name = "Service Account para Vertex AI Workbench by Terraform"
  project      = each.value.project_id
}