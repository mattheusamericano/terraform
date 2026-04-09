# ============================================================
# Secondary Ranges - GKE Pods e Services
# Criados na subnet existente do host project (Shared VPC)
# ============================================================

resource "google_compute_subnetwork" "gke_ranges" {
  for_each = var.gke_cluster_settings

  # Referencia a subnet existente — não cria uma nova
  name    = each.value.subnet_name
  region  = each.value.region
  project = each.value.network_project_id

  # Mantém o primary range existente
  ip_cidr_range = data.google_compute_subnetwork.subnet[each.key].ip_cidr_range
  network       = data.google_compute_network.vpc[each.key].self_link

  # Adiciona os secondary ranges para o GKE
  secondary_ip_range {
    range_name    = each.value.pods_range_name
    ip_cidr_range = each.value.pods_cidr
  }

  secondary_ip_range {
    range_name    = each.value.services_range_name
    ip_cidr_range = each.value.services_cidr
  }

  # Preserva ranges secundários já existentes na subnet
  lifecycle {
    ignore_changes = [
      secondary_ip_range,  # evita remover ranges de outros sistemas
    ]
  }
}

# Permissão para o SA do GKE usar a subnet no host project
resource "google_compute_subnetwork_iam_member" "gke_subnet_user" {
  for_each = var.gke_cluster_settings

  project    = each.value.network_project_id
  region     = each.value.region
  subnetwork = each.value.subnet_name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.project[each.key].number}@container-engine-robot.iam.gserviceaccount.com"
}
