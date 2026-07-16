resource "google_cloud_run_v2_service" "service" {

  for_each = var.cloud_run_settings

  name     = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  location = each.value.region
  project  = each.value.project_id
  #encryption_key = each.value.key_ring != null ? "projects/${each.value.kms_project_id}/locations/${each.value.region}/keyRings/${each.value.key_ring}/cryptoKeys/${each.value.key_crypto}" : null
  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.cloudrun_sa[each.key].email
    containers {
      image = each.value.image
      resources {
        limits = {
          cpu    = each.value.cpu
          memory = each.value.memory
        }
      }
    }

    dynamic "vpc_access" {
      for_each = each.value.vpc_connector != null ? [1] : []
      content {
        connector = each.value.vpc_connector
        egress    = "ALL_TRAFFIC"
      }

    }

    scaling {
      max_instance_count = each.value.max_scale
    }

  }

  depends_on = [
    google_service_account.cloudrun_sa,
    google_project_service_identity.run_identity
  ]

}