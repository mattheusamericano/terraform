# BigQuery Data Editor - leitura e escrita em tabelas
resource "google_project_iam_member" "bq_data_editor" {
  for_each = var.dataform_repository_settings

  project = each.value["project_id"]
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dataform_sa[each.key].email}"
}

# BigQuery Job User - executar jobs de query
resource "google_project_iam_member" "bq_job_user" {
  for_each = var.dataform_repository_settings

  project = each.value["project_id"]
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dataform_sa[each.key].email}"
}

# Secret Manager Secret Accessor - acessar o token do Git
resource "google_project_iam_member" "secret_accessor" {
  for_each = var.dataform_repository_settings

  project = each.value["project_id"]
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.dataform_sa[each.key].email}"
}

# Dataform Editor - gerenciar workspaces e compilações
resource "google_project_iam_member" "dataform_editor" {
  for_each = var.dataform_repository_settings

  project = each.value["project_id"]
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.dataform_sa[each.key].email}"
}

# Dataform Editor - gerenciar workspaces e compilações
resource "google_project_iam_member" "dataform_bucket_user" {
  for_each = var.dataform_repository_settings

  project = each.value["project_id"]
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.dataform_sa[each.key].email}"
}

# Dataform Admin - Acesso direto ao repositório como admin ao SA
resource "google_dataform_repository_iam_member" "sa_repository_admin" {
  for_each = var.dataform_repository_settings
  
  provider   = google-beta
  project    = each.value["project_id"]
  region     = each.value["region"]
  repository = google_dataform_repository.repository[each.key].name
  role       = "roles/dataform.admin"
  member     = "serviceAccount:${google_service_account.dataform_sa[each.key].email}"
}

#Acesso ao SA da API do Dataform para rodar os workflows com sucesso
resource "google_service_account_iam_member" "dataform_sa_token_creator" {
  for_each = var.dataform_repository_settings

  service_account_id    = google_service_account.dataform_sa[each.key].name
  role                  = "roles/iam.serviceAccountTokenCreator"
  member                = "serviceAccount:service-${data.google_project.project[each.key].number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

#Acesso ao SA da API do Dataform para rodar os workflows com sucesso
resource "google_service_account_iam_member" "dataform_sa_user" {
  for_each = var.dataform_repository_settings

  service_account_id    = google_service_account.dataform_sa[each.key].name
  role                  = "roles/iam.serviceAccountUser"
  member                = "serviceAccount:service-${data.google_project.project[each.key].number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

 #Permissão de Data Viewer no projeto Big Data "engenharia-bigdata-prd"
 resource "google_project_iam_member" "dataform_bigquery_viewer" {
  for_each   = var.dataform_repository_settings

  project         = "bigdata-1744049006"
  role            = "roles/bigquery.dataViewer"
  member          = "serviceAccount:${google_service_account.dataform_sa[each.key].email}"
 }
