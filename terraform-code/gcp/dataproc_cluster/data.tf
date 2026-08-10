# Necessário para resolver o project_number da SA/serviço do cluster e montar
# os emails dos service agents do Dataproc quando a VPC é compartilhada.
data "google_project" "shared_vpc_service_project" {
  for_each = { for k, v in var.dataproc_cluster_settings : k => v if v.shared_vpc_host_project != null }

  project_id = each.value.project_id
}
