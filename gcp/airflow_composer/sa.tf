# --------------------------------------------------------
# Service Account
# --------------------------------------------------------
resource "google_service_account" "composer_sa" {
  for_each = var.composer_settings

  account_id   = "sa-composer-${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name = "SA - Cloud Composer ${each.key} (${terraform.workspace})"
  description  = "Service Account do ambiente Composer ${each.key}"
  project      = each.value.project_id
}