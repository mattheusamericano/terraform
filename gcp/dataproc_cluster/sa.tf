# Uma Service Account dedicada por cluster, padrão sa-dp-<key>-<sigla>-<workspace>
resource "google_service_account" "cluster" {
  for_each = var.dataproc_cluster_settings

  project      = each.value.project_id
  account_id   = "sa-dp-${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name = coalesce(
    each.value.service_account_display_name,
    "SA do cluster Dataproc dp-${each.key}-${each.value.sigla}-${terraform.workspace}"
  )
  description = each.value.service_account_description
}
