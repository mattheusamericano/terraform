resource "google_workbench_instance" "instance" {
  for_each = var.workbench_settings

  name                          = "${each.key}-${each.value.sigla}-${terraform.workspace}" 
  location                      = "${each.value.region}-${each.value.zone}"
  disable_proxy_access          = false
  project                       = each.value["project_id"]
  desired_state                 = "ACTIVE"
  enable_third_party_identity   = false
  labels                        = each.value["labels"]

  gce_setup {
    disable_public_ip = true
    machine_type = each.value.workbench_machine_type
     service_accounts {
       email = google_service_account.workbench_sa[each.key].email
     }
    #container_image {
    #  repository = "${each.value.region}-docker.pkv.dev/${each.value.project_id}/${each.value.repository_name}/imagename" 
    #  tag = "latest"
    #}

    dynamic "accelerator_configs" {
      for_each = each.value.wbrv_accelerator_type != null && each.value.wbrv_accelerator_type != "" ? [1] : []
      content {
        type            = each.value["wbrv_accelerator_type"]
        core_count      = each.value["wbrv_accelerator_count"]
      }
    }

    dynamic "reservation_affinity" {
      for_each = try(each.value["wb_reservation_name"], null) != null ? [1] : []
      content {
        consume_reservation_type  = "RESERVATION_SPECIFIC"
        key                       = "compute.googleapis.com/reservation-name"
        values                    = [each.value["wb_reservation_name"]]
      }
    }

    metadata = {
      idle-timeout-seconds    = each.value["auto_shutdown"]
      enable-jupyterlab4      = true
    }

    data_disks {
      disk_size_gb    = each.value["workbench_disk_size_gb"]
      disk_type       = each.value["workbench_disk_type"]
      disk_encryption = each.value["workbench_disk_encryption"]
      kms_key         = "projects/${each.value.kms_project_id}/locations/${each.value.region}/keyRings/${each.value.key_ring}/cryptoKeys/${each.value.key_crypto}"
    }

    boot_disk {
      disk_size_gb    = 150
      disk_type       = "PD_BALANCED"
      disk_encryption =  each.value["workbench_disk_encryption"]
      kms_key         = "projects/${each.value.kms_project_id}/locations/${each.value.region}/keyRings/${each.value.key_ring}/cryptoKeys/${each.value.key_crypto}"
    }

    network_interfaces {
      network = "projects/${each.value.network_project_id}/global/networks/${each.value.name_vpc_shared}"
      subnet  = "projects/${each.value.network_project_id}/regions/${each.value.region}/subnetworks/${each.value.name_subnet_vpc_shared}"
    } 
   }

     depends_on = [
      google_service_account.workbench_sa,
      google_kms_crypto_key_iam_member.workbench_kms
      ]

  }
