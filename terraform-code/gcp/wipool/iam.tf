resource "google_service_account" "wipool_sa" {
    for_each = var.wipool_settings

    project         = each.value["project_id"]
    account_id      = each.value["wipool_sa_account_id"]
    display_name    = "Service Account para Workload Identity Pool by Terraform"

}

resource "google_service_account_iam_binding" "wipool_identity_binding" {
    for_each = var.wipool_settings

    depends_on         = [google_iam_workload_identity_pool_provider.identity_pool_provider]
    service_account_id = google_service_account.wipool_sa[each.key].name
    role               = "roles/iam.workloadIdentityUser"

    members = [
        "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.identity_pool[each.key].name}/attribute.repository_owner/${each.value.repository_owner}"
  ]
}