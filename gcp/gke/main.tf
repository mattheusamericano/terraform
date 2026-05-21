# ============================================================
# GKE Cluster Module
# ============================================================

resource "google_container_cluster" "cluster" {
  for_each = var.gke_cluster_settings
  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
  name                        = "gke-${each.value.sigla}-${terraform.workspace}"
  location                    = terraform.workspace == "prd" ? "${each.value.region}" : "${each.value.region}-${each.value.zone}"
  project                     = each.value.project_id
  resource_labels             = each.value.labels
  remove_default_node_pool    = true
  initial_node_count          = 1
  network                     = data.google_compute_network.vpc[each.key].self_link
  subnetwork                  = data.google_compute_subnetwork.subnet[each.key].self_link
  enable_shielded_nodes       = true
  deletion_protection         = false



  workload_identity_config {
    workload_pool = "${each.value.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = each.value.pods_range_name
    services_secondary_range_name = each.value.services_range_name
  }

###kubernetes_version    = "1.34.1" #Validar se vamos controlar versionamento ou o GCP
###Validar se vamos utilizar janela de atualização controlada pela GCP

  release_channel {
    channel = "STABLE"
  }

  maintenance_policy {
    recurring_window {
      start_time = "2026-03-22T00:00:00Z" # 06:00 BRT
      end_time   = "2026-03-22T06:00:00Z" # 10:00 BRT
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"  #Sabado e Domingo
    }
  }

  private_cluster_config {
    enable_private_nodes        = true
    private_endpoint_subnetwork = data.google_compute_subnetwork.subnet[each.key].self_link 
    enable_private_endpoint     = true
  }
  
  master_authorized_networks_config {
      cidr_blocks {
          cidr_block   = "10.250.0.0/16"
          display_name = "internal"
        }
      }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"] #Além dos que estão sendo habilitados tem esses: APISERVER, CONTROLLER_MANAGER, SCHEDULER
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }
 
  depends_on = [
    google_project_iam_member.gke_sa_roles
  ]
}

  #Por padrão é habilitado todos no monitoring config
  #monitoring_config {
  #  enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"] 
  #  }
  #}

  # --------------------------------------------------------
  # Binary Authorization / Serve para validar as imagens que são importadas para o cluster, se elas são confiaveis ou não com base em alguns parâmetros
  # --------------------------------------------------------
  #binary_authorization {
  #  evaluation_mode = terraform.workspace == "prd" ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  #}