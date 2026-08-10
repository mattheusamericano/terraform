resource "google_colab_runtime_template" "runtime-template" {
  for_each = var.colab_runtime_template_settings

  name                        = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name                = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  location                    = each.value["region"]
  description                 = "Full runtime template created by Terraform"
  labels                      = each.value["labels"]

  machine_spec {
    machine_type              = each.value["machine_type"]
    accelerator_type          = each.value["accelerator_type"]
    accelerator_count         = each.value["accelerator_count"]
  }

  data_persistent_disk_spec {
    disk_type                 = each.value["disk_type"]
    disk_size_gb              = each.value["disk_size_gb"]
  }

  network_spec {
    enable_internet_access    = false
    network                   = "projects/${each.value.network_project_id}/global/networks/${each.value.name_vpc_shared}"
    subnetwork                = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
  }

  idle_shutdown_config {
    idle_timeout = "3600s"
  }

}