# ============================================================
# Cloud Composer 3 - Data Sources
# ============================================================

# Captura o project_number automaticamente para cada projeto
# de serviço configurado, eliminando a necessidade de informar
# manualmente no tfvars.
data "google_project" "service" {
  for_each = var.composer_settings

  project_id = each.value.project_id
}
