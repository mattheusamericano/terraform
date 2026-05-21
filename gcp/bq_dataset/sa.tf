 resource "google_service_account" "bq_dataset_sa" {
     for_each = var.bq_dataset_settings
    
     account_id              = "sa-${each.value.sa_name}-${each.value.sigla}-${terraform.workspace}"
     display_name            = "Service Account para BigQuery by Terraform"
     project                 = each.value.project_id      
 }