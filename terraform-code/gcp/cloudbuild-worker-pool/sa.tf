# account_id precisa ter 6-30 caracteres, minúsculo, começando com letra.
# Combine chave/sigla/workspace com cuidado para não estourar o limite.
# Mesmo for_each de main.tf (var.worker_pool_settings) — uma SA por pool, com os
# campos vindos do bloco aninhado `service_account`.
resource "google_service_account" "cloudbuild" {
  for_each = var.worker_pool_settings

  project      = each.value.project_id
  account_id   = lower("cb-${each.key}-${each.value.sigla}-${terraform.workspace}")
  display_name = each.value.service_account.display_name
}
