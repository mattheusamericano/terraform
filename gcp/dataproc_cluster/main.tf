resource "google_dataproc_cluster" "this" {
  for_each = var.dataproc_cluster_settings

  name    = "dp-${each.key}-${each.value.sigla}-${terraform.workspace}"
  project = each.value.project_id
  region  = each.value.region

  cluster_config {
    staging_bucket = each.value.staging_bucket

    gce_cluster_config {
      zone                    = each.value.zone
      subnetwork              = each.value.subnetwork
      internal_ip_only        = each.value.internal_ip_only
      tags                    = each.value.tags
      service_account         = google_service_account.cluster[each.key].email
      service_account_scopes  = each.value.service_account_scopes
    }

    master_config {
      num_instances = each.value.master_settings.num_instances
      machine_type  = each.value.master_settings.machine_type

      disk_config {
        boot_disk_type    = each.value.master_settings.boot_disk_type
        boot_disk_size_gb = each.value.master_settings.boot_disk_size_gb
      }
    }

    worker_config {
      num_instances = each.value.worker_settings.num_instances
      machine_type  = each.value.worker_settings.machine_type

      disk_config {
        boot_disk_type    = each.value.worker_settings.boot_disk_type
        boot_disk_size_gb = each.value.worker_settings.boot_disk_size_gb
      }
    }

    software_config {
      image_version        = each.value.image_version
      optional_components  = each.value.optional_components
      override_properties  = each.value.override_properties
    }

    dynamic "autoscaling_config" {
      for_each = each.value.autoscaling_policy_uri != null ? [each.value.autoscaling_policy_uri] : []
      content {
        policy_uri = autoscaling_config.value
      }
    }

    endpoint_config {
      enable_http_port_access = each.value.enable_component_gateway
    }
  }

  labels = each.value.labels
}
