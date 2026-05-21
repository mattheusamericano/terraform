resource "google_container_node_pool" "nodepool_system" {
  for_each = var.gke_cluster_settings
  
  lifecycle {
    ignore_changes = [
      node_config[0].resource_labels,
    ]
  }

  name                  = "system"
  cluster               = google_container_cluster.cluster[each.key].name
  location              = terraform.workspace == "prd" ? "${each.value.region}" : "${each.value.region}-${each.value.zone}"
  project               = each.value.project_id
  max_pods_per_node     = each.value.max_pods_per_node

  autoscaling {
    min_node_count  = each.value.system_min_node_count
    max_node_count  = each.value.system_max_node_count
    location_policy = "BALANCED"
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 1
    max_unavailable = 0
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type          = each.value.system_machine_type
    disk_type             = "pd-ssd"
    disk_size_gb          = 50
    image_type            = "COS_CONTAINERD"
    spot                  = terraform.workspace == "prd" ? false : true
    
    labels = merge(each.value.labels, {
        environment   = terraform.workspace
        role          = "system"
        nodepool      = "system"
    })

    service_account = "${google_service_account.gke_sa[each.key].email}"
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    taint {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
  }