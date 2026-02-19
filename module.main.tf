# BigQuery dataform user and roles

# Service Account Compose - 
resource "google_service_account" "sa_gepld_global" {
  project      = var.project_id
  account_id   = "sa-gepld-global"
  display_name = "Conta Serviço para todo Projeto"

}

resource "google_service_account" "sa_gepld_integration" {
  project      = var.project_id
  account_id   = "sa-inte-gepld-prd"
  display_name = "Conta Serviço para todo Projeto"

}
resource "google_service_account" "sa_gepld_cloudrun" {
  project      = var.project_id
  account_id   = "sa-gepld-cloudrun"
  display_name = "Conta Serviço para todo Projeto"

}
locals {
  permissoes_sa_global = {
    permissao_service_agent_composer = "roles/composer.ServiceAgentV2Ext", 
    permissao_bigquery_admin= "roles/bigquery.admin", 
    permissao_storage_admin= "roles/storage.admin", 
    permissao_pub_sub_subscriber = "roles/pubsub.subscriber",
    permissao_pub_sub_publisher = "roles/pubsub.publisher",
    permissao_dataproc_worker= "roles/dataproc.worker",
    permissao_composer_worker= "roles/composer.worker",
    permissao_dataflow_worker= "roles/dataflow.worker"
  }
}

resource "google_project_iam_member" "permissoes_sa_gepld_global" {
  for_each = local.permissoes_sa_global
  project    = var.project_id
  role       = each.value
  member     = google_service_account.sa_gepld_global.member
   
}

resource "google_project_iam_member" "permissoes_sa_gepld_global_bigdata" {
  project    = "bigdata-1744049006"
  role       = "roles/bigquery.dataViewer"
  member     = google_service_account.sa_gepld_global.member
   
}

# Permite CRIAR buckets (e administrar Storage) para o grupo RISCCRVAR
resource "google_project_iam_member" "risccrvar_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "group:G_GCP_RISCCRVAR_DTSC@corp.caixa.gov.br"
}

# Permite CRIAR buckets (e administrar Storage) para o grupo RISCFAB
resource "google_project_iam_member" "riscfab_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
}

# Removido Permite executar Notebooks (Vertex AI Workbench) para o grupo RISCCRVAR

# Concede a role "Data Scientist" (predefinida) no projeto
resource "google_project_iam_member" "risccrvar_datascientist" {
  project = var.project_id
  role    = "roles/iam.dataScientist"
  member  = "group:G_GCP_RISCCRVAR_DTSC@corp.caixa.gov.br"
}

resource "google_project_iam_member" "riscfab_datascientist" {
  project = var.project_id
  role    = "roles/iam.dataScientist"
  member  = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
}


resource "google_service_account" "sa_composer" {
  project      = var.project_id
  account_id   = "sa-composer-gepld"
  display_name = "[Terraform] - Composer Service Account"
}
  
 resource "google_project_iam_member" "composer_log_entry" {
  project    = var.project_id
  role       = "roles/logging.logWriter"
  member     = google_service_account.sa_composer.member
  
}

 resource "google_project_iam_member" "composer_service_account_agent" {
  project    = var.project_id
  role       = "roles/composer.ServiceAgentV2Ext"
  member     = google_service_account.sa_composer.member
  
}

 resource "google_project_iam_member" "composer_service_agent" {
  project    = var.project_id
  role       = "roles/composer.ServiceAgentV2Ext"
  member     = "serviceAccount:service-${var.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"
  
}
resource "google_project_iam_member" "composer_bigquery" {
  project    = var.project_id
  role       = "roles/bigquery.admin"
  member     = google_service_account.sa_composer.member
}
 
resource "google_project_iam_member" "composer_storage" {
  project    = var.project_id
  role       = "roles/storage.admin"
  member     = google_service_account.sa_composer.member
}


resource "google_service_account" "dataform_runner_sa" {
  project      = var.project_id
  account_id   = "dataform-runner-sa"
  display_name = "Dataform Runner Service Account"
}

resource "google_project_iam_custom_role" "dataform_service_account_role" {
  project     = var.project_id
  role_id     = "dataformServiceAccountBasicRole"
  title       = "Dataform Service Account basic role"
  description = "[Terraform] - Basic permissions for Dataform User Service Account"
  permissions = var.bigquery_dataform_permissions
}

# Cloud build core secret acessor role

resource "google_service_account" "core_secret_accessor_sa" {
  project      = var.project_id
  account_id   = "core-secret-accessor-sa"
  display_name = "[Terraform] - Core secret accessor Service Account"
}

resource "google_project_iam_member" "core_secret_accessor" {
  project    = var.project_id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.core_secret_accessor_sa.email}"
  depends_on = [google_service_account.core_secret_accessor_sa]
}

locals {
  gcp_project_automate = { for k, v in var.gcp_project_automate : k => v }
}

# Secret Manager to Cloud Build Service Account permissions
# Collect secret data
data "google_project" "project" {
  for_each   = local.gcp_project_automate
  project_id = each.value.project-id
}

resource "google_project_iam_member" "cloud_build_service_sa_secret_admin" {
  for_each = local.gcp_project_automate
  project  = each.value.project-id
  role     = "roles/secretmanager.admin"
  member   = "serviceAccount:service-${data.google_project.project[each.value.project-id].number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Custom service roles to access services as impersonation - READ ONLY

resource "google_service_account" "log_viewer_service_sa" {
  project      = var.project_id
  account_id   = "logviewer-service-sa"
  display_name = "[Terraform] - Logging viewer Service Account"
}

resource "google_project_iam_member" "log_viewer_accessor" {
  project    = var.project_id
  role       = "roles/logging.viewer"
  member     = "serviceAccount:${google_service_account.log_viewer_service_sa.email}"
  depends_on = [google_service_account.log_viewer_service_sa]
}

# Custom roles to access services as impersonation - READ / WRITE

resource "google_service_account" "log_writer_service_sa" {
  project      = var.project_id
  account_id   = "logwriter-service-sa" #sa-risco-bs-comercial-pf-dev
  display_name = "[Terraform] - Logging writer Service Account"
}

resource "google_project_iam_member" "log_writer_accessor" {
  project    = var.project_id
  role       = "roles/logging.logWriter"
  member     = "serviceAccount:${google_service_account.log_writer_service_sa.email}"
  depends_on = [google_service_account.log_writer_service_sa]
}

# resource "google_project_iam_member" "log_writer_viewer" {
#   project    = var.project_id
#   role       = "roles/logging.logViewer"
#   member     = "serviceAccount:${google_service_account.log_writer_service_sa.email}"
#   depends_on = [google_service_account.log_writer_service_sa]
# }

resource "google_project_iam_member" "log_writer_bq_editor_member" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.log_writer_service_sa.email}"
}

# resource "google_project_iam_member" "log_writer_bq_reader_member" {
#   project = var.project_id
#   role    = "roles/bigquery.dataReader"
#   member  = "serviceAccount:${google_service_account.log_writer_service_sa.email}"
# }

# Custom roles to access services as impersonation - ADMIN

resource "google_service_account" "log_admin_service_sa" {
  project      = var.project_id
  account_id   = "logadmin-service-sa"
  display_name = "[Terraform] - Logging Admin Service Account"
}

resource "google_project_iam_member" "log_admin_accessor" {
  project    = var.project_id
  role       = "roles/logging.admin"
  member     = "serviceAccount:${google_service_account.log_admin_service_sa.email}"
  depends_on = [google_service_account.log_admin_service_sa]
}


resource "google_project_iam_member" "ml_platform_user_riscfab" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
}


# Criação dos papéis básicos

resource "google_project_iam_custom_role" "machine_learning_viewer" {
  project     = var.project_id
  role_id     = "ENG_VIEWER"
  title       = "ENG_VIEWER"
  description = "[Terraform] - Permissions to allow view resources related to Machine Learning practices within GCP"
  permissions = var.ml_viewer_permissions
}

resource "google_project_iam_custom_role" "machine_learning_engineer" {
  project     = var.project_id
  role_id     = "ENG_MLOPS"
  title       = "ENG_MLOPS"
  description = "[Terraform] - Basic permissions to allow Machine Learning Engineer role to use resources related to Machine Learning practices within GCP"
  permissions = var.ml_engineer_permissions
}

resource "google_project_iam_custom_role" "data_engineer" {
  project     = var.project_id
  role_id     = "ENG_DADOS"
  title       = "ENG_DADOS"
  description = "[Terraform] - Basic permissions to allow Data Engineer role to use resources related to Machine Learning practices within GCP"
  permissions = var.data_engineer_permissions
}

resource "google_project_iam_custom_role" "machine_learning_data_scientist" {
  project     = var.project_id
  role_id     = "CIENTISTA_DADOS"
  title       = "CIENTISTA_DADOS"
  description = "[Terraform] - Basic permissions to allow Machine Learning Data Scientist role to use resources related to Machine Learning practices within GCP"
  permissions = var.ml_data_scientist_permissions
}


# Machine Learning roles

# Authoritative - forçar a existência
resource "google_project_iam_binding" "machine_learning_engineer_project_group_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.machine_learning_engineer.name
  members = [
    var.ml_engineer_org_group,
  ]
}

resource "google_project_iam_binding" "machine_learning_google_role" {
  project = var.project_id
  role    = "roles/iam.mlEngineer"
  members = [
    var.ml_engineer_org_group,
  ]
}

resource "google_project_iam_binding" "machine_learning_google_noteviwer" {
  project = var.project_id
  role    = "roles/notebooks.runner"
  members = [
    var.ml_engineer_org_group,
    var.ml_data_scientist_org_group
  ]
}

# IAP-secured Web App User
resource "google_project_iam_member" "ml_engineer_iap_https_resource_accessor" {
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = var.ml_engineer_org_group
}

# Cloud Run Developer
resource "google_project_iam_member" "ml_engineer_cloud_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = var.ml_engineer_org_group
}


resource "google_project_iam_member" "machine_learning_engineer_project_viewer" {
  project = var.project_id
  role    = "roles/aiplatform.viewer"
  member  = var.ml_engineer_org_group
}

resource "google_project_iam_member" "machine_learning_engineer_iam_viewer" {
  project = var.project_id
  role    = "roles/iam.roleViewer"
  member  = var.ml_engineer_org_group
}

resource "google_project_iam_member" "machine_learning_engineer_connection_viewer" {
  project = var.project_id
  role    = "roles/cloudbuild.connectionAdmin"
  member  = var.ml_engineer_org_group
}

# Data Scientist roles

# Authoritative - forçar a existência
resource "google_project_iam_binding" "ml_data_scientist_project_group_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.machine_learning_data_scientist.name
  members = [
    var.ml_data_scientist_org_group,
  ]
}

resource "google_project_iam_member" "ml_data_scientist_project_viewer" {
  project = var.project_id
  role    = "roles/aiplatform.viewer"
  member  = var.ml_data_scientist_org_group
}

resource "google_project_iam_member" "ml_data_scientist_iam_viewer" {
  project = var.project_id
  role    = "roles/iam.roleViewer"
  member  = var.ml_data_scientist_org_group
}

# Data Engineer roles

# Authoritative - forçar a existência
resource "google_project_iam_binding" "data_engineer_project_group_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.data_engineer.name
  members = [
    var.data_engineer_org_group,
  ]
}

# Non-authoritative - Inclusão
resource "google_project_iam_member" "data_engineer_project_viewer" {
  project = var.project_id
  role    = "roles/aiplatform.viewer"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "data_engineer_iam_viewer" {
  project = var.project_id
  role    = "roles/iam.roleViewer"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "data_engineer_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "data_engineer_dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = var.data_engineer_org_group
}

resource "google_project_iam_member" "role_compose_admin" {
  project    = var.project_id
  role       = "roles/composer.admin"
  member  = var.data_engineer_org_group
  }

resource "google_project_iam_member" "data_engineer_dataproc_worker" {
  project = var.project_id
  role    = "roles/dataproc.worker"
  member  = var.data_engineer_org_group
}

resource "google_project_service" "servicenetworking" {
  project            = var.network_project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service_identity" "servicenetworking_agent" {
  provider = google-beta

  project = var.network_project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_project_service_identity" "vertex" {
  provider = google-beta

  project = var.network_project_id
  service = "aiplatform.googleapis.com"
}


resource "google_project_iam_member" "servicenetworking_agent" {
  project = var.network_project_id
  role    = "roles/servicenetworking.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.servicenetworking_agent.email}"
}

resource "google_service_account" "vertex-workbench-sa" {
  project      = var.project_id
  account_id   = "vertex-workbench-sa"
  display_name = "vertex-workbench-sa"
}

resource "google_project_service_identity" "secret_manager_agent" {
  provider = google-beta

  project = var.project_id
  service = "secretmanager.googleapis.com"
}

locals {
  users_network = {
    notebooks_service_agent = "serviceAccount:service-${data.google_project.project[var.project_id].number}@gcp-sa-notebooks.iam.gserviceaccount.com",
    workbench_sa            = "serviceAccount:${google_service_account.vertex-workbench-sa.email}",
    compute_service_agent   = "serviceAccount:service-${data.google_project.project[var.project_id].number}@compute-system.iam.gserviceaccount.com",
    cloudrun_sa             = "${google_service_account.sa_gepld_cloudrun.member}"
  }
  users_kms = {
    notebooks_service_agent = "serviceAccount:service-${data.google_project.project[var.project_id].number}@gcp-sa-notebooks.iam.gserviceaccount.com",
    workbench_sa            = "serviceAccount:${google_service_account.vertex-workbench-sa.email}",
    compute_service_agent   = "serviceAccount:service-${data.google_project.project[var.project_id].number}@compute-system.iam.gserviceaccount.com",
    smanager_agent          = "serviceAccount:service-${data.google_project.project[var.project_id].number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
  }
  users_secrets = {
    compute_service_agent = "serviceAccount:service-${data.google_project.project[var.project_id].number}@compute-system.iam.gserviceaccount.com",
    smanager_agent        = "serviceAccount:service-${data.google_project.project[var.project_id].number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
  }
}

resource "google_compute_subnetwork_iam_member" "ai-service-agent-role-network" {
  for_each   = local.users_network
  project    = var.network_project_id
  role       = "roles/compute.networkUser"
  region     = var.region
  subnetwork = "projects/${var.network_project_id}/regions/${var.region}/subnetworks/${var.name_subnet_vpc_shared}"
  member     = each.value
  depends_on = [google_service_account.vertex-workbench-sa]
}

resource "google_kms_crypto_key_iam_member" "ai-service-agent-role-kms" {
  for_each      = local.users_kms
  crypto_key_id = "projects/${var.kms_project_id}/locations/${var.region}/keyRings/${var.key_ring}/cryptoKeys/${var.key_crypto}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
  depends_on    = [google_service_account.vertex-workbench-sa]
}
/*
resource "google_artifact_registry_repository_iam_member" "sa-reader-role-repo-python" {
  project    = var.project_id
  location   = var.region
  repository = var.repository_python_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.vertex-workbench-sa.email}"
  depends_on = [google_service_account.vertex-workbench-sa]
}
*/
resource "google_service_account_iam_binding" "act_as_permission" {
  service_account_id = google_service_account.vertex-workbench-sa.id
  role               = "roles/iam.serviceAccountUser"
  members            = var.workbench_members
}

/*
resource "google_secret_manager_secret_iam_member" "github_app_id" {
  for_each  = local.users_secrets
  project   = var.project_id
  secret_id = "projects/${var.project_id}/secrets/${var.sm_app_id}"
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

resource "google_secret_manager_secret_iam_member" "github_client_id" {
  for_each  = local.users_secrets
  project   = var.project_id
  secret_id = "projects/${var.project_id}/secrets/${var.sm_installation_id}"
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

resource "google_secret_manager_secret_iam_member" "github_key_pem" {
  for_each  = local.users_secrets
  project   = var.project_id
  secret_id = "projects/${var.project_id}/secrets/${var.sm_key_pem}"
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}
*/
