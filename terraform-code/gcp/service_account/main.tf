# Service Account genérica, padrão sa-<chave>-<sigla>-<workspace>
resource "google_service_account" "sa" {
  for_each = var.sa_settings

  project      = each.value.project_id
  account_id   = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name = coalesce(
    each.value.display_name,
    "SA ${each.key} (${terraform.workspace})"
  )
  description = each.value.description
  disabled    = each.value.disabled
}
