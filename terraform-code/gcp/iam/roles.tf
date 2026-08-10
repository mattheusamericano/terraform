resource "google_project_iam_member" "core_secret_accessor" {
  project     = var.iam_settings["iam"].project_id
  role        = "roles/secretmanager.secretAccessor"
  member      = "serviceAccount:${google_service_account.sa["sa-cr-acc"].email}"
}

resource "google_project_iam_member" "log_viewer_accessor" {
  project    = var.iam_settings["iam"].project_id
  role       = "roles/logging.viewer"
  member     = "serviceAccount:${google_service_account.sa["sa-lg-vw"].email}"
}

resource "google_project_iam_member" "log_writer_accessor" {
  project    = var.iam_settings["iam"].project_id
  role       = "roles/logging.logWriter"
  member     = "serviceAccount:${google_service_account.sa["sa-lg-wr"].email}"
}

resource "google_project_iam_member" "log_writer_bq_editor_member" {
  project    = var.iam_settings["iam"].project_id
  role    = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.sa["sa-lg-wr"].email}"
}

resource "google_project_iam_member" "log_admin_accessor" {
  project    = var.iam_settings["iam"].project_id
  role       = "roles/logging.admin"
  member     = "serviceAccount:${google_service_account.sa["sa-lg-adm"].email}"
}

resource "google_project_iam_member" "role_datascientist" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/iam.dataScientist"
  member  = var.ml_data_scientist_org_group
}

resource "google_project_iam_member" "riscfab_datascientist" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/iam.dataScientist"
  member  = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
}

resource "google_project_iam_member" "ml_engineer_iap_https_resource_accessor" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = var.ml_engineer_org_group
}

resource "google_project_iam_member" "ml_engineer_cloud_run_developer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/run.developer"
  member  = var.ml_engineer_org_group
}

resource "google_project_iam_member" "machine_learning_engineer_project_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/aiplatform.viewer"
  member  = var.ml_engineer_org_group
}

resource "google_project_iam_member" "machine_learning_engineer_iam_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/iam.roleViewer"
  member  = var.ml_engineer_org_group
}

resource "google_project_iam_member" "machine_learning_engineer_connection_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/cloudbuild.connectionAdmin"
  member  = var.ml_engineer_org_group
}

resource "google_project_iam_member" "ml_data_scientist_project_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/aiplatform.user"
  member  = var.ml_data_scientist_org_group
}

resource "google_project_iam_member" "ml_data_scientist_iam_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/iam.roleViewer"
  member  = var.ml_data_scientist_org_group
}

resource "google_project_iam_member" "ml_data_scientist_iam_df_editor" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/dataform.editor"
  member  = var.ml_data_scientist_org_group
}

resource "google_project_iam_member" "data_engineer_project_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/aiplatform.viewer"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "data_engineer_iam_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/iam.roleViewer"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "data_engineer_bq_editor" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/bigquery.dataEditor"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "data_engineer_dataform_editor" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/dataform.editor"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "ml_platform_user_riscfab" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/aiplatform.admin"
  member  = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
}

resource "google_project_iam_member" "role_compose_admin" {
  project    = var.iam_settings["iam"].project_id
  role       = "roles/composer.admin"
  member  = var.data_engineer_org_group
  }

resource "google_project_iam_member" "data_engineer_dataproc_worker" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/dataproc.worker"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "group_data_scientist_stg_admin" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/storage.admin"
  member  = var.ml_data_scientist_org_group
}

resource "google_project_iam_member" "group_data_engineer_stg_admin" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/storage.admin"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "group_data_engineer_notebooks_run" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/notebooks.runner"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "group_data_engineer_log_viewer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/logging.viewer"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "group_data_engineer_ml_engineer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/iam.mlEngineer"
  member  = var.data_engineer_org_group
}