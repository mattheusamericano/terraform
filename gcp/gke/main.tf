# ============================================================
# GKE Cluster Module
# ============================================================

resource "google_container_cluster" "cluster" {
  for_each = var.gke_cluster_settings

  name     = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  location = each.value.region
  project  = each.value.project_id

  # --------------------------------------------------------
  # Remove o default node pool imediatamente
  # Nodepools serão gerenciados pelo módulo separado
  # --------------------------------------------------------
  remove_default_node_pool = true
  initial_node_count       = 1

  # --------------------------------------------------------
  # Networking - Private Cluster
  # --------------------------------------------------------
  network    = data.google_compute_network.vpc[each.key].self_link
  subnetwork = data.google_compute_subnetwork.subnet[each.key].self_link

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = terraform.workspace == "prd" ? true : false
    master_ipv4_cidr_block  = each.value.master_ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = each.value.pods_range_name
    services_secondary_range_name = each.value.services_range_name
  }

  # --------------------------------------------------------
  # Master authorized networks
  # --------------------------------------------------------
  dynamic "master_authorized_networks_config" {
    for_each = length(each.value.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = each.value.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr
          display_name = cidr_blocks.value.name
        }
      }
    }
  }

  # --------------------------------------------------------
  # Addons
  # --------------------------------------------------------
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

  # --------------------------------------------------------
  # Workload Identity
  # --------------------------------------------------------
  workload_identity_config {
    workload_pool = "${each.value.project_id}.svc.id.goog"
  }

  # --------------------------------------------------------
  # Binary Authorization
  # --------------------------------------------------------
  binary_authorization {
    evaluation_mode = terraform.workspace == "prd" ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # --------------------------------------------------------
  # Logging & Monitoring
  # --------------------------------------------------------
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    managed_prometheus {
      enabled = true
    }
  }

  # --------------------------------------------------------
  # Release Channel
  # --------------------------------------------------------
  release_channel {
    channel = terraform.workspace == "prd" ? "STABLE" : "REGULAR"
  }

  # --------------------------------------------------------
  # Maintenance
  # --------------------------------------------------------
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T09:00:00Z" # 06:00 BRT
      end_time   = "2024-01-01T13:00:00Z" # 10:00 BRT
      recurrence = "FREQ=WEEKLY;BYDAY=SU"  # Domingo
    }
  }

  # --------------------------------------------------------
  # Security
  # --------------------------------------------------------
  enable_shielded_nodes = true

  security_posture_config {
    mode               = terraform.workspace == "prd" ? "BASIC" : "DISABLED"
    vulnerability_mode = terraform.workspace == "prd" ? "VULNERABILITY_BASIC" : "VULNERABILITY_DISABLED"
  }

  # --------------------------------------------------------
  # KMS (opcional)
  # --------------------------------------------------------
  dynamic "database_encryption" {
    for_each = each.value.kms_key_name != null ? [1] : []
    content {
      state    = "ENCRYPTED"
      key_name = data.google_kms_crypto_key.gke_key[each.key].id
    }
  }

  resource_labels = merge(each.value.labels, {
    environment = terraform.workspace
    managed_by  = "terraform"
  })

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }

  depends_on = [
    google_project_iam_member.gke_sa_roles
  ]
}
