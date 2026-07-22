# Flatten necessario porque cada cluster pode conceder acesso a N access
# groups por papel (Manager/Operator/Viewer) - mesmo padrao ja usado nos
# modulos cos_instance e cos_bucket.
locals {
  manager_bindings = flatten([
    for k, v in var.roks_cluster_settings : [
      for ag in v.iam_bindings.managers : { cluster_key = k, access_group_id = ag }
    ]
  ])
  manager_bindings_map = { for item in local.manager_bindings : "${item.cluster_key}-${item.access_group_id}" => item }

  operator_bindings = flatten([
    for k, v in var.roks_cluster_settings : [
      for ag in v.iam_bindings.operators : { cluster_key = k, access_group_id = ag }
    ]
  ])
  operator_bindings_map = { for item in local.operator_bindings : "${item.cluster_key}-${item.access_group_id}" => item }

  viewer_bindings = flatten([
    for k, v in var.roks_cluster_settings : [
      for ag in v.iam_bindings.viewers : { cluster_key = k, access_group_id = ag }
    ]
  ])
  viewer_bindings_map = { for item in local.viewer_bindings : "${item.cluster_key}-${item.access_group_id}" => item }
}
