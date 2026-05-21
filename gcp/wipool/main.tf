resource "google_iam_workload_identity_pool" "identity_pool" {
    for_each = var.wipool_settings

    project                   = each.value["project_id"]
    workload_identity_pool_id = each.key
    display_name              = each.value["wipool_display_name"]
}

resource "google_iam_workload_identity_pool_provider" "identity_pool_provider" {
    for_each = var.wipool_settings
    
    project                            = each.value["project_id"]
    workload_identity_pool_id          = google_iam_workload_identity_pool.identity_pool[each.key].workload_identity_pool_id
    workload_identity_pool_provider_id = each.value["wipool_provider_id"]
    display_name                       = each.value["wipool_display_name"]
    attribute_condition                = each.value["attribute_condition"]
    attribute_mapping                  = each.value["attribute_mapping"]

  oidc {
    issuer_uri = "${each.value.wipool_issuer_uri}"
  }
}