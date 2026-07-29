resource "google_dataproc_session_template" "this" {
  for_each = var.session_template_settings

  name     = "projects/${each.value.project_id}/locations/${each.value.location}/sessionTemplates/st-${each.key}-${each.value.sigla}-${terraform.workspace}"
  project  = each.value.project_id
  location = each.value.location
  labels   = each.value.labels

  runtime_config {
    version          = each.value.runtime_settings.version
    container_image  = each.value.runtime_settings.container_image
    properties       = each.value.runtime_settings.properties
  }

  environment_config {
    execution_config {
      service_account = each.value.execution_settings.service_account
      subnetwork_uri  = each.value.execution_settings.subnetwork_uri
      staging_bucket  = each.value.execution_settings.staging_bucket
      network_tags    = each.value.execution_settings.network_tags
      kms_key         = each.value.execution_settings.kms_key
      ttl             = each.value.execution_settings.ttl
      idle_ttl        = each.value.execution_settings.idle_ttl

      authentication_config {
        user_workload_authentication_type = each.value.execution_settings.auth_type
      }
    }

    dynamic "peripherals_config" {
      for_each = (
        each.value.peripherals_settings.metastore_service != null ||
        each.value.peripherals_settings.spark_history_dataproc_cluster != null
      ) ? [1] : []

      content {
        metastore_service = each.value.peripherals_settings.metastore_service

        dynamic "spark_history_server_config" {
          for_each = each.value.peripherals_settings.spark_history_dataproc_cluster != null ? [1] : []
          content {
            dataproc_cluster = each.value.peripherals_settings.spark_history_dataproc_cluster
          }
        }
      }
    }
  }

  dynamic "jupyter_session" {
    for_each = each.value.session_type == "jupyter" ? [1] : []
    content {
      kernel       = each.value.jupyter_settings.kernel
      display_name = each.value.jupyter_settings.display_name
    }
  }

  dynamic "spark_connect_session" {
    for_each = each.value.session_type == "spark_connect" ? [1] : []
    content {}
  }

  depends_on = [google_kms_crypto_key_iam_member.session_kms]
}
