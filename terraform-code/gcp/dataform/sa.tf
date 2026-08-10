resource "google_service_account" "dataform_sa" {
  for_each = var.dataform_repository_settings

  project      = each.value["project_id"]
  account_id   = each.value["service_account_id"]
  display_name = "Dataform Service Account"
  description  = "Service Account used by Dataform created by Terraform"
}
