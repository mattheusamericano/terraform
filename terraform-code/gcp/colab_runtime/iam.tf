#Permissão para sub-rede do projeto de infra compartilhado 
 resource "google_compute_subnetwork_iam_member" "vertex-service-agent-role-network" {
   for_each = var.colab_runtime_template_settings

   project       = "${each.value.network_project_id}"
   role          = "roles/compute.networkUser"
   region        =  each.value["region"]
   subnetwork    = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
   member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
 }

#Permissão para sub-rede do projeto de infra compartilhado 
 resource "google_compute_subnetwork_iam_member" "vertex-service-agent-network-viewer" {
   for_each = var.colab_runtime_template_settings

   project       = "${each.value.network_project_id}"
   role          = "roles/compute.networkViewer"
   region        =  each.value["region"]
   subnetwork    = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
   member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
 }

 #Permissão para sub-rede do projeto de infra compartilhado 
 resource "google_compute_subnetwork_iam_member" "vertex-nb-service-role-network-user" {
   for_each = var.colab_runtime_template_settings

   project       = "${each.value.network_project_id}"
   role          = "roles/compute.networkUser"
   region        =  each.value["region"]
   subnetwork    = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
   member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-vertex-nb.iam.gserviceaccount.com"
 }

 #Permissão para o runtime_user utilizar o runtime_template
 #resource "google_project_iam_member" "aiplatform_user" {
 # for_each = var.colab_runtime_template_settings

 # project                 = google_colab_runtime_template.runtime-template[each.key].project
 # role                    = "roles/aiplatform.colabEnterpriseUser"
 # member                 = "user:${each.value["runtime_user"]}"
 #}