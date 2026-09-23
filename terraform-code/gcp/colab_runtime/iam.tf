resource "google_compute_subnetwork_iam_member" "vertex-service-agent-role-network" {
  for_each = var.colab_runtime_template_settings

  project    = each.value.network_project_id
  role       = "roles/compute.networkUser"
  region     = each.value["region"]
  subnetwork = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
  member     = "serviceAccount:service-${data.google_project.project[each.value.project_id].number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

resource "google_compute_subnetwork_iam_member" "vertex-service-agent-network-viewer" {
  for_each = var.colab_runtime_template_settings

  project    = each.value.network_project_id
  role       = "roles/compute.networkViewer"
  region     = each.value["region"]
  subnetwork = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
  member     = "serviceAccount:service-${data.google_project.project[each.value.project_id].number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

resource "google_compute_subnetwork_iam_member" "vertex-nb-service-role-network-user" {
  for_each = var.colab_runtime_template_settings

  project    = each.value.network_project_id
  role       = "roles/compute.networkUser"
  region     = each.value["region"]
  subnetwork = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
  member     = "serviceAccount:service-${data.google_project.project[each.value.project_id].number}@gcp-sa-vertex-nb.iam.gserviceaccount.com"
}

resource "google_project_service_identity" "colab_runtime_template_aiplatform" {
  for_each = local.colab_runtime_template_cmek_projects

  provider = google-beta
  project  = each.key
  service  = "aiplatform.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "colab_runtime_template" {
  for_each = local.colab_runtime_template_cmek_bindings

  crypto_key_id = each.value.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.colab_runtime_template_aiplatform[each.value.project_id].email}"
}
