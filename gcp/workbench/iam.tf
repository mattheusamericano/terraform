locals {
    kms_unique_bindings = {
        for k, v in var.workbench_settings :
        "${v.project_id}||${v.kms_project_id}||${v.region}||${v.key_ring}||${v.key_crypto}" => v...
    }

    kms_unique_bindings_flat = {
        for key, val in local.kms_unique_bindings :
        key => val[0]
    }

    network_unique_bindings = {
        for k, v in var.workbench_settings :
        "${v.network_project_id}||${v.region}||${v.name_subnet_vpc_shared}" => v...
    }

    network_unique_bindings_flat = {
        for key, val in local.network_unique_bindings : 
        key => val[0]
    }
}

resource "google_project_iam_member" "sa-reader-role-repo" {
    for_each = var.workbench_settings
    
    project    = each.value["project_id"]
    role       = "roles/artifactregistry.writer"
    member     = google_service_account.workbench_sa[each.key].member
    
    depends_on = [google_service_account.workbench_sa]
}

#Permissão de criptografia (KMS) para Service Accounts
 resource "google_kms_crypto_key_iam_member" "workbench_kms" {
     for_each = var.workbench_settings

     crypto_key_id               = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
     role                        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
     member                      = google_service_account.workbench_sa[each.key].member
 }

 #Permissão de criptografia (KMS) para Service Agent Notebook 
 resource "google_kms_crypto_key_iam_member" "workbench_kms_notebook" {
     for_each = local.kms_unique_bindings_flat

     crypto_key_id               = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
     role                        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
     member                      = "serviceAccount:${google_project_service_identity.notebooks_identity[each.value.project_id].email}"
 }

 #Permissão de criptografia (KMS) para Service Agent Notebook 
 resource "google_kms_crypto_key_iam_member" "workbench_kms_compute" {
     for_each = local.kms_unique_bindings_flat

     crypto_key_id               = "${each.value.kms_project_id}/${each.value.region}/${each.value.key_ring}/${each.value.key_crypto}"
     role                        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
     member                      = "serviceAccount:service-${data.google_project.project[each.value.project_id].number}@compute-system.iam.gserviceaccount.com"
 }

#Permissão para sub-rede do projeto de infra compartilhado 
 resource "google_compute_subnetwork_iam_member" "ai-service-agent-role-network" {
   for_each   = var.workbench_settings

   project       = "${each.value.network_project_id}"
   role          = "roles/compute.networkUser"
   region        = each.value.region
   subnetwork    = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
   member        = google_service_account.workbench_sa[each.key].member
   depends_on    = [google_service_account.workbench_sa]
 }

#Permissão para sub-rede do projeto de infra compartilhado para Service Agent
 resource "google_compute_subnetwork_iam_member" "ai-service-agent-role-network-svc-agent" {
   for_each   = local.network_unique_bindings_flat

   project       = "${each.value.network_project_id}"
   role          = "roles/compute.networkUser"
   region        = each.value.region
   subnetwork    = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
   member        = "serviceAccount:${google_project_service_identity.notebooks_identity[each.value.project_id].email}"
   depends_on    = [google_service_account.workbench_sa]
 }

 #Permissão de Data Viewer no projeto Big Data "engenharia-bigdata-prd"
 resource "google_project_iam_member" "workbench_bigquery_viewer" {
  for_each   = var.workbench_settings

  project         = "bigdata-1744049006"
  role            = "roles/bigquery.dataViewer"
  member          = google_service_account.workbench_sa[each.key].member
 }

 #Permissão de Data Viewer no próprio projeto
 resource "google_project_iam_member" "workbench_bigquery_viewer_this_project" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/bigquery.dataEditor"
  member          = google_service_account.workbench_sa[each.key].member
 }

 #Permissão de BigQuery JobUser no próprio projeto
 resource "google_project_iam_member" "workbench_bigquery_jobuser_this_project" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/bigquery.jobUser"
  member          = google_service_account.workbench_sa[each.key].member
 }

 #Permissão de BigQuery User no próprio projeto
 resource "google_project_iam_member" "workbench_bigquery_user_this_project" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/bigquery.user"
  member          = google_service_account.workbench_sa[each.key].member
 }

 #Permissão de Bucket User no próprio projeto
 resource "google_project_iam_member" "workbench_bucket_user_this_project" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/storage.objectUser"
  member          = google_service_account.workbench_sa[each.key].member
 }

  #Permissão de Project Settings Viewer no próprio projeto
 resource "google_project_iam_member" "workbench_project_viewer" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/osconfig.projectFeatureSettingsViewer"
  member          = google_service_account.workbench_sa[each.key].member
 }
 
 #Permissão de Vertex AI User
 resource "google_project_iam_member" "workbench_vertex_ai_user" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/aiplatform.user"
  member          = google_service_account.workbench_sa[each.key].member
 }

  #Permissão de Cloud Run user
 resource "google_project_iam_member" "workbench_cloudrun_user" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/run.developer"
  member          = google_service_account.workbench_sa[each.key].member
 }

  #Permissão de LogWriter
 resource "google_project_iam_member" "workbench_log_writer" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/logging.logWriter"
  member          = google_service_account.workbench_sa[each.key].member
 }

  #Permissão de Service Usage Viewer
 resource "google_project_iam_member" "workbench_service_usage_viewer" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/serviceusage.serviceUsageViewer"
  member          = google_service_account.workbench_sa[each.key].member
 }

  #Permissão de Dataproc Editor
 resource "google_project_iam_member" "workbench_dataproc_editor" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/dataproc.editor"
  member          = google_service_account.workbench_sa[each.key].member
 }

  #Permissão de Dataproc Worker
 resource "google_project_iam_member" "workbench_dataproc_worker" {
  for_each   = var.workbench_settings

  project         = "${each.value.project_id}"
  role            = "roles/dataproc.worker"
  member          = google_service_account.workbench_sa[each.key].member
 }