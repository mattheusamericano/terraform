resource "google_sql_database_instance" "main" {
  for_each = var.cloud_sql_instance_settings

  lifecycle {
    ignore_changes = [
      settings[0].disk_size, # Evita recriação por autoresize
      root_password
    ]
  }
  name                = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  database_version    = each.value["database_version"]
  region              = each.value["region"]
  project             = each.value["project_id"]
  root_password       = local.admin_password
  deletion_protection = false
  encryption_key_name = data.google_kms_crypto_key.keycrypto[each.key].id

  settings {
    tier                    = each.value["tier"]
    availability_type       = terraform.workspace == "prd" ? "REGIONAL" : "ZONAL"
    disk_type               = each.value["disk_type"]
    disk_size               = each.value["disk_size"]
    disk_autoresize         = terraform.workspace == "prd" ? true : false
    disk_autoresize_limit   = each.value["disk_autoresize_limit"]
    user_labels             = each.value["labels"]

    password_validation_policy {
      min_length                = 12
      reuse_interval            = 3
      complexity                = "COMPLEXITY_DEFAULT"
      enable_password_policy   = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      location                       = each.value["region"]

      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = data.google_compute_network.vpc[each.key].self_link
      ssl_mode                                      = "ENCRYPTED_ONLY"

      #dynamic "authorized_networks" {
      #  for_each = var.authorized_networks
      #  content {
      #    name  = authorized_networks.value.name
      #    value = authorized_networks.value.cidr
      #  }
      }

    maintenance_window {
      day          = 7 #Domingo
      hour         = 6 # 06:00UTC = 03:00 Brasilia
      update_track = "stable"
    }
    
    insights_config {
      query_insights_enabled  = terraform.workspace == "prd" ? true : false
      query_string_length     = 1024
      record_client_address   = false
    }
  
  }
  
}