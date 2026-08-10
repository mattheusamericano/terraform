resource "google_spanner_instance" "this" {
  for_each = var.spanner_instance_settings

  project          = each.value.project_id
  name             = "${each.key}_${each.value.sigla}_${terraform.workspace}"
  display_name     = coalesce(each.value.display_name, "${each.key}-${each.value.sigla}-${terraform.workspace}")
  config           = each.value.config
  processing_units = each.value.processing_units
  edition          = each.value.edition
  labels           = each.value.labels
}
