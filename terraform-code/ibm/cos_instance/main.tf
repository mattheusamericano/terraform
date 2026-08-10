resource "ibm_resource_instance" "this" {
  for_each = var.cos_instance_settings

  name              = "cos-${each.value.sigla}-${terraform.workspace}"
  service           = "cloud-object-storage"
  plan              = each.value.plan
  location          = each.value.location
  resource_group_id = each.value.resource_group_id
  tags              = each.value.tags
}
