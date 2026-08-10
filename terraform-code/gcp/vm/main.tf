# ============================================================
# Stop Schedule (opcional)
# ============================================================

resource "google_compute_resource_policy" "stop_schedule" {
  for_each = { for k, vm in var.vm_settings : k => vm if vm.stop_schedule != null }

  name    = "${each.key}-${each.value.sigla}-stop-${terraform.workspace}"
  project = each.value.project_id
  region  = each.value.subnetwork_region

  instance_schedule_policy {
    time_zone = each.value.stop_schedule.timezone

    vm_stop_schedule {
      schedule = each.value.stop_schedule.schedule
    }
  }
}

# ============================================================
# Compute Instance
# ============================================================

resource "google_compute_instance" "vm" {
  for_each = var.vm_settings

  name         = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  project      = each.value.project_id
  zone         = each.value.zone
  machine_type = each.value.machine_type

  # --------------------------------------------------------
  # Boot disk
  # image           = imagem pública (ex: "debian-cloud/debian-12")
  # image_self_link = imagem personalizada (mutuamente exclusivo com image)
  # --------------------------------------------------------
  boot_disk {
    initialize_params {
      image = each.value.boot_disk.image_self_link != null ? each.value.boot_disk.image_self_link : each.value.boot_disk.image
      size  = each.value.boot_disk.size
      type  = each.value.boot_disk.type
    }

    dynamic "disk_encryption_key" {
      for_each = each.value.kms_key_self_link != null ? [1] : []
      content {
        kms_key_self_link = each.value.kms_key_self_link
      }
    }
  }

  # --------------------------------------------------------
  # Networking
  # --------------------------------------------------------
  network_interface {
    network    = data.google_compute_network.vpc[each.key].self_link
    subnetwork = data.google_compute_subnetwork.subnet[each.key].self_link

    # IP público apenas se habilitado
    dynamic "access_config" {
      for_each = each.value.enable_public_ip ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  tags = each.value.network_tags

  # --------------------------------------------------------
  # Service Account
  # --------------------------------------------------------
  dynamic "service_account" {
    for_each = each.value.service_account_email != null ? [1] : []
    content {
      email  = each.value.service_account_email
      scopes = each.value.scopes
    }
  }

  # --------------------------------------------------------
  # Stop Schedule
  # --------------------------------------------------------
  resource_policies = each.value.stop_schedule != null ? [
    google_compute_resource_policy.stop_schedule[each.key].self_link
  ] : []

  # --------------------------------------------------------
  # Shielded VM - habilitado em todos os ambientes
  # --------------------------------------------------------
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # --------------------------------------------------------
  # KMS - Confidential Computing (opcional)
  # --------------------------------------------------------
  dynamic "confidential_instance_config" {
    for_each = each.value.kms_key_self_link != null ? [1] : []
    content {
      enable_confidential_compute = true
    }
  }

  # --------------------------------------------------------
  # Scheduling - restart automático apenas em prd
  # --------------------------------------------------------
  scheduling {
    automatic_restart   = terraform.workspace == "prd" ? true : false
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  labels = merge(each.value.labels, {
    environment = terraform.workspace
    managed_by  = "terraform"
  })

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}
