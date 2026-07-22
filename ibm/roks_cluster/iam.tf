# IMPORTANTE: o provider IBM nao documenta oficialmente um atributo estavel
# para escopar policies a UM cluster especifico (tipo o "clusterid"). Por isso,
# o escopo real destes bindings e o servico containers-kubernetes DENTRO do
# resource_group_id do cluster - nao o cluster individualmente. Ver Observacoes
# no README para como isolar clusters (1 resource group por cluster).
resource "ibm_iam_access_group_policy" "manager" {
  for_each = local.manager_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Manager"]

  resources {
    service           = "containers-kubernetes"
    resource_group_id = var.roks_cluster_settings[each.value.cluster_key].resource_group_id
  }
}

resource "ibm_iam_access_group_policy" "operator" {
  for_each = local.operator_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Operator"]

  resources {
    service           = "containers-kubernetes"
    resource_group_id = var.roks_cluster_settings[each.value.cluster_key].resource_group_id
  }
}

resource "ibm_iam_access_group_policy" "viewer" {
  for_each = local.viewer_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Viewer"]

  resources {
    service           = "containers-kubernetes"
    resource_group_id = var.roks_cluster_settings[each.value.cluster_key].resource_group_id
  }
}
