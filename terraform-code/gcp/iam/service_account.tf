# Service Account Compose - 
resource "google_service_account" "sa" {
  for_each = var.sa_settings

  account_id   = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  project      = each.value["project_id"]
  display_name = each.value["display_name"]
}
