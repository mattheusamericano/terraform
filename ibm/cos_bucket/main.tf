resource "ibm_cos_bucket" "this" {
  for_each = var.cos_bucket_settings

  bucket_name          = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  resource_instance_id = each.value.instance_crn

  storage_class = each.value.storage_class
  endpoint_type = each.value.endpoint_type
  force_delete  = each.value.force_delete
  hard_quota    = each.value.hard_quota
  allowed_ip    = each.value.allowed_ip
  object_lock   = each.value.object_lock
  kms_key_crn   = each.value.kms_key_crn

  region_location       = each.value.location_type == "region" ? each.value.location : null
  cross_region_location = each.value.location_type == "cross_region" ? each.value.location : null
  single_site_location  = each.value.location_type == "single_site" ? each.value.location : null

  object_versioning {
    enable = each.value.object_versioning_enabled
  }

  dynamic "retention_rule" {
    for_each = each.value.retention_rule != null ? [each.value.retention_rule] : []
    content {
      default   = retention_rule.value.default
      maximum   = retention_rule.value.maximum
      minimum   = retention_rule.value.minimum
      permanent = retention_rule.value.permanent
    }
  }

  dynamic "activity_tracking" {
    for_each = each.value.activity_tracking != null ? [each.value.activity_tracking] : []
    content {
      read_data_events     = activity_tracking.value.read_data_events
      write_data_events    = activity_tracking.value.write_data_events
      management_events    = activity_tracking.value.management_events
      activity_tracker_crn = activity_tracking.value.activity_tracker_crn
    }
  }

  dynamic "metrics_monitoring" {
    for_each = each.value.metrics_monitoring != null ? [each.value.metrics_monitoring] : []
    content {
      usage_metrics_enabled   = metrics_monitoring.value.usage_metrics_enabled
      request_metrics_enabled = metrics_monitoring.value.request_metrics_enabled
      metrics_monitoring_crn  = metrics_monitoring.value.metrics_monitoring_crn
    }
  }
}
