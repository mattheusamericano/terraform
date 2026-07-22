resource "ibm_container_vpc_cluster" "this" {
  for_each = var.roks_cluster_settings

  name              = "roks-${each.value.sigla}-${terraform.workspace}"
  vpc_id            = each.value.vpc_id
  resource_group_id = each.value.resource_group_id

  offering     = "openshift"
  kube_version = each.value.kube_version
  flavor       = each.value.flavor
  worker_count = each.value.worker_count

  cos_instance_crn = each.value.cos_instance_crn
  entitlement      = each.value.entitlement

  disable_public_service_endpoint = each.value.disable_public_service_endpoint
  wait_till                       = each.value.wait_till

  tags = each.value.tags

  worker_labels = merge(each.value.labels, {
    environment = terraform.workspace
    nodepool    = "default"
  })

  dynamic "zones" {
    for_each = each.value.zones
    content {
      name      = zones.value.name
      subnet_id = zones.value.subnet_id
    }
  }
}
