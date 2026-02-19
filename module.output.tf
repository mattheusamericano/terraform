output "sa-workbench-email" {
  value = google_service_account.vertex-workbench-sa.email
}

output "sa_cloud_run_email" {
  value = google_service_account.sa_gepld_cloudrun.email
}

output "sa_integration_email" {
  value = google_service_account.sa_gepld_integration.email
}
