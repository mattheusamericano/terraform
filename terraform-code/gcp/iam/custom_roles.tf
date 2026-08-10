resource "google_project_iam_custom_role" "dataform_service_account_role" {
  project       = var.iam_settings["iam"].project_id
  role_id       = "dataformServiceAccountBasicRole"
  title         = "Dataform Service Account basic role"
  description   = "[Terraform] - Basic permissions for Dataform User Service Account"
  permissions   = var.permissions_bigquery_dataform
}

resource "google_project_iam_custom_role" "machine_learning_viewer" {
  project     = var.iam_settings["iam"].project_id
  role_id     = "ENG_VIEWER"
  title       = "ENG_VIEWER"
  description = "[Terraform] - Permissions to allow view resources related to Machine Learning practices within GCP"
  permissions = var.permissions_ml_viewer
}

resource "google_project_iam_custom_role" "machine_learning_engineer" {
  project     = var.iam_settings["iam"].project_id
  role_id     = "ENG_MLOPS"
  title       = "ENG_MLOPS"
  description = "[Terraform] - Basic permissions to allow Machine Learning Engineer role to use resources related to Machine Learning practices within GCP"
  permissions = var.permissions_ml_engineer
}

resource "google_project_iam_custom_role" "data_engineer" {
  project     = var.iam_settings["iam"].project_id
  role_id     = "ENG_DADOS"
  title       = "ENG_DADOS"
  description = "[Terraform] - Basic permissions to allow Data Engineer role to use resources related to Machine Learning practices within GCP"
  permissions = var.permissions_data_engineer
}

resource "google_project_iam_custom_role" "machine_learning_data_scientist" {
  project     = var.iam_settings["iam"].project_id
  role_id     = "CIENTISTA_DADOS"
  title       = "CIENTISTA_DADOS"
  description = "[Terraform] - Basic permissions to allow Machine Learning Data Scientist role to use resources related to Machine Learning practices within GCP"
  permissions = var.permissions_ml_data_scientis
}