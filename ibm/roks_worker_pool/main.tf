resource "ibm_container_vpc_worker_pool" "this" {
  for_each = var.roks_worker_pool_settings

  cluster           = each.value.cluster_id
  vpc_id            = each.value.vpc_id
  resource_group_id = each.value.resource_group_id

  worker_pool_name = each.key
  flavor           = each.value.flavor
  worker_count     = each.value.worker_count
  entitlement      = each.value.entitlement

  labels = merge(each.value.labels, {
    environment = terraform.workspace
    nodepool    = each.key
  })

  dynamic "zones" {
    for_each = each.value.zones
    content {
      name      = zones.value.name
      subnet_id = zones.value.subnet_id
    }
  }

  dynamic "taints" {
    for_each = each.value.taints
    content {
      key    = taints.value.key
      value  = taints.value.value
      effect = taints.value.effect
    }
  }
}
