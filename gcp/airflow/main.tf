# ============================================================
# Cloud Composer 3 - Module
# ============================================================

# --------------------------------------------------------
# Service Account
# --------------------------------------------------------
resource "google_service_account" "composer_sa" {
  for_each = var.composer_settings

  account_id   = "sa-composer-${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name = "SA - Cloud Composer ${each.key} (${terraform.workspace})"
  description  = "Service Account do ambiente Composer ${each.key}"
  project      = each.value.project_id
}

# --------------------------------------------------------
# IAM Bindings - SA no projeto host (Shared VPC)
# --------------------------------------------------------
resource "google_project_iam_member" "composer_sa_host_network" {
  for_each = var.composer_settings

  project = each.value.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.composer_sa[each.key].email}"
}

# --------------------------------------------------------
# IAM Bindings - SA no projeto de serviço
# --------------------------------------------------------
resource "google_project_iam_member" "composer_sa_roles" {
  for_each = {
    for pair in flatten([
      for k, v in var.composer_settings : [
        for role in v.sa_roles : {
          key        = "${k}__${role}"
          env_key    = k
          project_id = v.project_id
          role       = role
          email      = google_service_account.composer_sa[k].email
        }
      ]
    ]) : pair.key => pair
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${each.value.email}"
}

# --------------------------------------------------------
# IAM Binding - Composer Agent no projeto host (Shared VPC)
# --------------------------------------------------------
resource "google_project_iam_member" "composer_agent_host_network" {
  for_each = var.composer_settings

  project = each.value.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:service-${data.google_project.service[each.key].number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "composer_agent_roles" {
  for_each = var.composer_settings

  project = each.value.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${data.google_project.service[each.key].number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

# --------------------------------------------------------
# Secret Manager - senhas geradas pelo Terraform
# (ex: db_password, credenciais internas)
# Segredos externos (tokens de API, etc.) devem ser
# gerenciados fora do Terraform e apenas referenciados aqui.
# --------------------------------------------------------

locals {
  # Flatten: um entry por (ambiente, secret_name)
  generated_secrets_flat = flatten([
    for k, v in var.composer_settings : [
      for secret_name, cfg in v.generated_secrets : {
        key         = "${k}__${secret_name}"
        env_key     = k
        project_id  = v.project_id
        secret_name = secret_name
        length      = cfg.length
        special     = cfg.special
      }
    ]
  ])
}

# Gera senhas aleatórias para cada secret configurado
resource "random_password" "generated" {
  for_each = {
    for pair in local.generated_secrets_flat : pair.key => pair
  }

  length           = each.value.length
  special          = each.value.special
  override_special = "!#$%&*()-_=+[]{}<>:?"

  lifecycle {
    ignore_changes = all # Nunca rotaciona automaticamente
  }
}

# Cria o secret no Secret Manager
resource "google_secret_manager_secret" "generated" {
  for_each = {
    for pair in local.generated_secrets_flat : pair.key => pair
  }

  secret_id = "airflow-var-${each.value.env_key}-${each.value.secret_name}-${terraform.workspace}"
  project   = each.value.project_id

  replication {
    auto {}
  }

  labels = {
    environment = terraform.workspace
    managed_by  = "terraform"
    composer    = each.value.env_key
    generated   = "true"
  }
}

# Publica a versão inicial com o valor gerado
resource "google_secret_manager_secret_version" "generated" {
  for_each = {
    for pair in local.generated_secrets_flat : pair.key => pair
  }

  secret      = google_secret_manager_secret.generated[each.key].id
  secret_data = random_password.generated[each.key].result

  lifecycle {
    ignore_changes = [secret_data] # Valor gerado uma vez; rotação é manual
  }
}

# IAM - SA do Composer acessa os secrets gerados
resource "google_secret_manager_secret_iam_member" "composer_sa_generated_access" {
  for_each = {
    for pair in local.generated_secrets_flat : pair.key => pair
  }

  project   = each.value.project_id
  secret_id = google_secret_manager_secret.generated[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.composer_sa[each.value.env_key].email}"
}

# --------------------------------------------------------
# Cloud Composer 3 Environment
# --------------------------------------------------------
resource "google_composer_environment" "composer" {
  for_each = var.composer_settings

  name    = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  region  = each.value.region
  project = each.value.project_id

  labels = merge(each.value.labels, {
    environment = terraform.workspace
    managed_by  = "terraform"
  })

  config {
    # --------------------------------------------------------
    # Software Configuration
    # --------------------------------------------------------
    software_config {
      image_version = each.value.image_version # ex: "composer-3-airflow-2.9"

      dynamic "airflow_config_overrides" {
        for_each = length(each.value.airflow_config_overrides) > 0 ? [each.value.airflow_config_overrides] : []
        content {
          # flatten map -> cada entry vira um bloco (key = "section-option")
        }
      }

      airflow_config_overrides = each.value.airflow_config_overrides
      env_variables            = each.value.env_variables
      pypi_packages            = each.value.pypi_packages

      # Secret Manager como backend de variáveis e connections
      dynamic "cloud_data_lineage_integration" {
        for_each = each.value.enable_data_lineage ? [1] : []
        content {
          enabled = true
        }
      }
    }

    # --------------------------------------------------------
    # Workloads Configuration (Composer 3)
    # --------------------------------------------------------
    workloads_config {
      scheduler {
        cpu        = each.value.scheduler_cpu
        memory_gb  = each.value.scheduler_memory_gb
        storage_gb = each.value.scheduler_storage_gb
        count      = each.value.scheduler_count
      }

      triggerer {
        cpu       = each.value.triggerer_cpu
        memory_gb = each.value.triggerer_memory_gb
        count     = each.value.triggerer_count
      }

      web_server {
        cpu        = each.value.web_server_cpu
        memory_gb  = each.value.web_server_memory_gb
        storage_gb = each.value.web_server_storage_gb
      }

      worker {
        cpu        = each.value.worker_cpu
        memory_gb  = each.value.worker_memory_gb
        storage_gb = each.value.worker_storage_gb
        min_count  = each.value.worker_min_count
        max_count  = each.value.worker_max_count
      }
    }

    # --------------------------------------------------------
    # Environment Size (Composer 3)
    # --------------------------------------------------------
    environment_size = each.value.environment_size # ENVIRONMENT_SIZE_SMALL/MEDIUM/LARGE

    # --------------------------------------------------------
    # Node Configuration (Shared VPC)
    # --------------------------------------------------------
    node_config {
      service_account = google_service_account.composer_sa[each.key].email
      network         = "projects/${each.value.host_project_id}/global/networks/${each.value.network_name}"
      subnetwork      = "projects/${each.value.host_project_id}/regions/${each.value.region}/subnetworks/${each.value.subnetwork_name}"

      ip_allocation_policy {
        cluster_secondary_range_name  = each.value.pods_ip_range_name
        services_secondary_range_name = each.value.services_ip_range_name
      }
    }

    # --------------------------------------------------------
    # Private Environment (sem IP público)
    # --------------------------------------------------------
    private_environment_config {
      enable_private_endpoint                = each.value.enable_private_endpoint
      enable_privately_used_public_ips       = each.value.enable_privately_used_public_ips
      cloud_composer_network_ipv4_cidr_block = each.value.composer_network_cidr
    }

    # --------------------------------------------------------
    # Encryption (KMS) - opcional
    # --------------------------------------------------------
    dynamic "encryption_config" {
      for_each = each.value.kms_key_name != null ? [each.value.kms_key_name] : []
      content {
        kms_key_name = encryption_config.value
      }
    }

    # --------------------------------------------------------
    # Maintenance Window - opcional
    # --------------------------------------------------------
    dynamic "maintenance_window" {
      for_each = each.value.maintenance_window != null ? [each.value.maintenance_window] : []
      content {
        start_time = maintenance_window.value.start_time
        end_time   = maintenance_window.value.end_time
        recurrence = maintenance_window.value.recurrence
      }
    }

    # --------------------------------------------------------
    # Data Retention (Composer 3)
    # --------------------------------------------------------
    dynamic "data_retention_config" {
      for_each = each.value.task_logs_retention_days != null ? [each.value.task_logs_retention_days] : []
      content {
        task_logs_retention_config {
          storage_mode           = "CLOUD_LOGGING_AND_CLOUD_STORAGE"
          retention_period_in_days = data_retention_config.value
        }
      }
    }
  }

  depends_on = [
    google_project_iam_member.composer_sa_host_network,
    google_project_iam_member.composer_agent_host_network,
    google_project_iam_member.composer_agent_roles,
    google_secret_manager_secret_iam_member.composer_sa_generated_access,
  ]
}
