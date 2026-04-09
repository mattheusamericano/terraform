# ============================================================
# GKE Nodepool Module
# ============================================================

resource "google_container_node_pool" "nodepool" {
  for_each = var.gke_nodepool_settings

  name     = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  cluster  = each.value.cluster_name
  location = each.value.region
  project  = each.value.project_id

  # --------------------------------------------------------
  # Autoscaling
  # --------------------------------------------------------
  autoscaling {
    min_node_count  = each.value.min_node_count
    max_node_count  = each.value.max_node_count
    location_policy = "BALANCED"
  }

  # --------------------------------------------------------
  # Upgrade strategy - surge upgrade para zero downtime
  # --------------------------------------------------------
  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 1
    max_unavailable = 0
  }

  # --------------------------------------------------------
  # Node management
  # --------------------------------------------------------
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # --------------------------------------------------------
  # Node config
  # --------------------------------------------------------
  node_config {
    machine_type = each.value.machine_type
    disk_type    = each.value.disk_type
    disk_size_gb = each.value.disk_size_gb
    image_type   = "COS_CONTAINERD"

    service_account = each.value.gke_sa_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # Shielded nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Spot nodes para ambientes não-prd (economia de custo)
    spot = terraform.workspace == "prd" ? false : true

    labels = merge(each.value.labels, {
      environment = terraform.workspace
      managed_by  = "terraform"
      nodepool    = each.key
    })

    # Taints opcionais
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  lifecycle {
    ignore_changes = [
      node_config[0].resource_labels,
    ]
    # Cria novo nodepool antes de destruir o antigo
    create_before_destroy = true
  }
}
