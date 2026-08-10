# --------------------------------------------------------
# Cloud Composer 3 Environment
# --------------------------------------------------------
resource "google_composer_environment" "composer" {
  for_each = var.composer_settings
  lifecycle {
    ignore_changes = [
      config[0].node_config[0].ip_allocation_policy[0]
    ]
  }

  name    = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  region  = each.value.region
  project = each.value.project_id

  labels = each.value.labels

  config {
    # --------------------------------------------------------
    # Software Configuration
    # --------------------------------------------------------

    enable_private_environment = true
    enable_private_builds_only = true

    software_config {
      image_version    = each.value.image_version
      pypi_packages    = each.value.pypi_packages

      # Secret Manager como backend de variáveis e connections
      dynamic "cloud_data_lineage_integration" {
        for_each = each.value.enable_data_lineage ? [1] : []
        content {
          enabled = true
        }
      }
    }

    # --------------------------------------------------------
    # Workloads Configuration (Composer 3)
    # --------------------------------------------------------
    workloads_config {
      scheduler {
        cpu        = each.value.scheduler_cpu
        memory_gb  = each.value.scheduler_memory_gb
        storage_gb = each.value.scheduler_storage_gb
        count      = each.value.scheduler_count
      }

      triggerer {
        cpu       = each.value.triggerer_cpu
        memory_gb = each.value.triggerer_memory_gb
        count     = each.value.triggerer_count
      }

      web_server {
        cpu        = each.value.web_server_cpu
        memory_gb  = each.value.web_server_memory_gb
        storage_gb = each.value.web_server_storage_gb
      }

      worker {
        cpu        = each.value.worker_cpu
        memory_gb  = each.value.worker_memory_gb
        storage_gb = each.value.worker_storage_gb
        min_count  = each.value.worker_min_count
        max_count  = each.value.worker_max_count
      }
    }

    # --------------------------------------------------------
    # Environment Size (Composer 3)
    # --------------------------------------------------------
    environment_size = each.value.environment_size # ENVIRONMENT_SIZE_SMALL/MEDIUM/LARGE

    # --------------------------------------------------------
    # Node Configuration (Shared VPC)
    # --------------------------------------------------------
    node_config {
      service_account = google_service_account.composer_sa[each.key].email
      network         = "projects/${each.value.network_project_id}/global/networks/${each.value.network_name}"
      subnetwork      = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.subnetwork_name}"

      ip_allocation_policy {
        cluster_secondary_range_name  = each.value.pods_ip_range_name
        services_secondary_range_name = each.value.services_ip_range_name
        use_ip_aliases                = false
      }
    }
    # --------------------------------------------------------
    # Encryption (KMS) - opcional
    # --------------------------------------------------------
    dynamic "encryption_config" {
      for_each = each.value.key_ring != null ? [1] : []
      content {
        kms_key_name = data.google_kms_crypto_key.composer[each.key].id
      }
    }

    # --------------------------------------------------------
    # Maintenance Window - opcional
    # --------------------------------------------------------
    dynamic "maintenance_window" {
      for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
      content {
        start_time = maintenance_window.value.start_time
        end_time   = maintenance_window.value.end_time
        recurrence = maintenance_window.value.recurrence
      }
    }

    # --------------------------------------------------------
    # Data Retention (Composer 3)
    # --------------------------------------------------------
    data_retention_config {
      airflow_metadata_retention_config{
        retention_days = 30
        retention_mode = "RETENTION_MODE_ENABLED"
      }
    }
  }

  depends_on = [
    google_project_iam_member.composer_sa_host_network,
    google_project_iam_member.composer_agent_host_network,
    google_project_iam_member.composer_agent_roles,
  ]
}