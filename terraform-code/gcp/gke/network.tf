# ============================================================
# Secondary Ranges - GKE Pods e Services
# Criados na subnet existente do host project (Shared VPC)
# ============================================================

#resource "google_compute_subnetwork" "gke_ranges" {
#  for_each = var.gke_cluster_settings

  #name    = each.value.subnet_name
  #region  = each.value.region
  #project = each.value.network_project_id

  # Mantém o primary range existente
  #ip_cidr_range = data.google_compute_subnetwork.subnet[each.key].ip_cidr_range
  #network       = data.google_compute_network.vpc[each.key].self_link

  # Adiciona os secondary ranges para o GKE
  #secondary_ip_range {
  #  range_name    = each.value.pods_range_name #tornar variável e colocar valor default
  #  ip_cidr_range = each.value.pods_cidr
  #}

  #secondary_ip_range {
  #  range_name    = each.value.services_range_name #tornar variável e colocar valor default
  #  ip_cidr_range = each.value.services_cidr
  #}

  #log_config {
  #  aggregation_interval        = "INTERVAL_5_SEC"
  #  flow_sampling               = 0.5
  #  metadata                    = "INCLUDE_ALL_METADATA"
  #}

  # Preserva ranges secundários já existentes na subnet
  #lifecycle {
  #  ignore_changes = [
  #    secondary_ip_range,  # evita remover ranges de outros sistemas
  #  ]
  #}
#}

# ============================================================
# IAM - NETWORKING
# ============================================================

# Permissão para o SA do GKE usar a subnet no host project
resource "google_compute_subnetwork_iam_member" "gke_subnet_user" {
  for_each = var.gke_cluster_settings

  project    = each.value.network_project_id
  region     = each.value.region
  subnetwork = each.value.subnet_name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.project[each.key].number}@container-engine-robot.iam.gserviceaccount.com"
}

# Permissão para o SA do GKE usar a subnet no host project
resource "google_project_iam_member" "gke_host_service_agent" {
  for_each = var.gke_cluster_settings

  project    = each.value.network_project_id
  role       = "roles/container.hostServiceAgentUser"
  member     = "serviceAccount:service-${data.google_project.project[each.key].number}@container-engine-robot.iam.gserviceaccount.com"
}

# Permissão para o SA do GKE usar a subnet no host project
resource "google_project_iam_member" "gke_network_user" {
  for_each = var.gke_cluster_settings

  project    = each.value.network_project_id
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.project[each.key].number}@container-engine-robot.iam.gserviceaccount.com"
}

# Permissão no projeto do cluster
resource "google_project_iam_member" "fleet_sa_network_admin" {
  for_each = var.gke_cluster_settings

  project = each.value.network_project_id
  role    = "roles/compute.networkAdmin"
  member  = local.fleet_sa[each.key]
}