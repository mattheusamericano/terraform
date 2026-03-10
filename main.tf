# ============================================================
# Cloud SQL - Production Module
# ============================================================

resource "google_sql_database_instance" "main" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  # Prevent accidental deletion in production
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type # REGIONAL para HA (failover automático)
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = true
    disk_autoresize_limit = var.disk_autoresize_limit

    # --------------------------------------------------------
    # Backup Configuration
    # --------------------------------------------------------
    backup_configuration {
      enabled                        = true
      binary_log_enabled             = var.database_version == "MYSQL_8_0" ? true : null
      point_in_time_recovery_enabled = var.database_version == "POSTGRES_15" ? true : null
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # --------------------------------------------------------
    # Networking - Private IP only (sem exposição pública)
    # --------------------------------------------------------
    ip_configuration {
      ipv4_enabled                                  = false  # Desabilita IP público
      private_network                               = var.vpc_network_id
      enable_private_path_for_google_cloud_services = true
      require_ssl                                   = true   # Força TLS

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # --------------------------------------------------------
    # Maintenance Window
    # --------------------------------------------------------
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = "stable"
    }

    # --------------------------------------------------------
    # Insights & Query Performance
    # --------------------------------------------------------
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false
    }

    # --------------------------------------------------------
    # Flags de configuração do banco
    # --------------------------------------------------------
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    user_labels = var.labels
  }

  lifecycle {
    ignore_changes = [
      settings[0].disk_size, # Evita recriação por autoresize
    ]
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# ============================================================
# Read Replica (opcional, para leitura distribuída)
# ============================================================
resource "google_sql_database_instance" "read_replica" {
  count = var.read_replica_count

  name                 = "${var.instance_name}-replica-${count.index}"
  database_version     = var.database_version
  region               = var.read_replica_region != null ? var.read_replica_region : var.region
  project              = var.project_id
  master_instance_name = google_sql_database_instance.main.name
  deletion_protection  = var.deletion_protection

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.read_replica_tier != null ? var.read_replica_tier : var.tier
    availability_type = "ZONAL"
    disk_type         = var.disk_type
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled     = false
      private_network  = var.vpc_network_id
      require_ssl      = true
    }

    insights_config {
      query_insights_enabled = true
      query_string_length    = 1024
    }

    user_labels = merge(var.labels, { role = "read-replica" })
  }
}

# ============================================================
# Databases
# ============================================================
resource "google_sql_database" "databases" {
  for_each = toset(var.databases)

  name     = each.value
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

# ============================================================
# Users (senha gerenciada via Secret Manager)
# ============================================================
resource "google_sql_user" "users" {
  for_each = var.db_users

  name     = each.key
  instance = google_sql_database_instance.main.name
  password = each.value.password
  project  = var.project_id

  lifecycle {
    ignore_changes = [password]
  }
}

# ============================================================
# Private Service Connection (VPC Peering com Google)
# ============================================================
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.instance_name}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_network_id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# ============================================================
# IAM - Service Account para acesso via Cloud SQL Proxy
# ============================================================
resource "google_service_account" "sql_proxy_sa" {
  count = var.create_proxy_service_account ? 1 : 0

  account_id   = "${var.instance_name}-sql-proxy"
  display_name = "Cloud SQL Proxy SA - ${var.instance_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "sql_client" {
  count = var.create_proxy_service_account ? 1 : 0

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.sql_proxy_sa[0].email}"
}
