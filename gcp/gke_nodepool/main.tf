resource "google_container_node_pool" "nodepool" {
  for_each = var.gke_nodepool_settings

  name                  = "${each.key}"
  cluster               = each.value["cluster_name"]
  location              = terraform.workspace == "prd" ? "${each.value.region}" : "${each.value.region}-${each.value.zone}"
  project               = each.value["project_id"]
  max_pods_per_node     = each.value["max_pods_per_node"]

  autoscaling {
    min_node_count  = each.value["min_node_count"]
    max_node_count  = each.value["max_node_count"]
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
    machine_type          = each.value["machine_type"]

    disk_type             = each.value["disk_type"]
    disk_size_gb          = each.value["disk_size_gb"]
    image_type            = "COS_CONTAINERD"

    service_account = each.value["gke_sa_email"]
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Spot nodes para ambientes não-prd (economia de custo)
    spot = terraform.workspace == "prd" ? false : true

    labels = merge(each.value.labels, {
      environment = terraform.workspace
      role        = "user"
      nodepool    = each.key
    })

    #taint {
    #    key    = "nuvem.caixa/nodepoolname"
    #    value  = each.value["taint_value"]
    #    effect = "NO_SCHEDULE"
    #  }
    }

  lifecycle {
    ignore_changes = [
      node_config[0].resource_labels,
    ]
  }
}