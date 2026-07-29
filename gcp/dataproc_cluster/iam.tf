# Bindings aditivos (o módulo não é dono do projeto/recursos externos, apenas concede papéis pontuais)

# Obrigatório: sem roles/dataproc.worker no próprio projeto, a SA anexada às VMs do
# cluster não consegue operar (falha com "missing required permissions: dataproc.agents.create,
# dataproc.agents.delete, storage.buckets.get, storage.objects...*"). viewer/editor abaixo
# são para quem administra o cluster via API, não substituem o worker.
resource "google_project_iam_member" "cluster_sa_worker" {
  for_each = { for k, v in var.dataproc_cluster_settings : k => v if v.grant_self_project_dataproc_roles }

  project = each.value.project_id
  role    = "roles/dataproc.worker"
  member  = "serviceAccount:${google_service_account.cluster[each.key].email}"
}

resource "google_project_iam_member" "cluster_sa_viewer" {
  for_each = { for k, v in var.dataproc_cluster_settings : k => v if v.grant_self_project_dataproc_roles }

  project = each.value.project_id
  role    = "roles/dataproc.viewer"
  member  = "serviceAccount:${google_service_account.cluster[each.key].email}"
}

resource "google_project_iam_member" "cluster_sa_editor" {
  for_each = { for k, v in var.dataproc_cluster_settings : k => v if v.grant_self_project_dataproc_roles }

  project = each.value.project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${google_service_account.cluster[each.key].email}"
}

resource "google_project_iam_member" "shared_vpc_network_user" {
  for_each = local.shared_vpc_bindings

  project = each.value.host_project
  role    = "roles/compute.networkUser"
  member  = each.value.member
}

resource "google_project_iam_member" "additional_bindings" {
  for_each = local.additional_bindings

  project = each.value.project_id
  role    = each.value.role
  member  = each.value.member
}
