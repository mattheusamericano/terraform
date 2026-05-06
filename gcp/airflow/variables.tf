# ============================================================
# Cloud Composer 3 - Variables
# ============================================================

variable "composer_settings" {
  description = "Mapa de configurações dos ambientes Cloud Composer 3"
  type = map(object({
    # --------------------------------------------------------
    # Identificação
    # --------------------------------------------------------
    project_id      = string
    host_project_id = string # Projeto host da Shared VPC
    sigla           = string
    region          = string

    # --------------------------------------------------------
    # Imagem
    # --------------------------------------------------------
    image_version = optional(string, "composer-3-airflow-2.9")

    # --------------------------------------------------------
    # Rede (Shared VPC)
    # --------------------------------------------------------
    network_name                   = string
    subnetwork_name                = string
    pods_ip_range_name             = string
    services_ip_range_name         = string
    enable_private_endpoint        = optional(bool, true)
    enable_privately_used_public_ips = optional(bool, false)
    composer_network_cidr          = optional(string, null)

    # --------------------------------------------------------
    # Tamanho do ambiente
    # --------------------------------------------------------
    environment_size = optional(string, "ENVIRONMENT_SIZE_SMALL")

    # --------------------------------------------------------
    # Scheduler
    # --------------------------------------------------------
    scheduler_cpu        = optional(number, 0.5)
    scheduler_memory_gb  = optional(number, 1.875)
    scheduler_storage_gb = optional(number, 1)
    scheduler_count      = optional(number, 1)

    # --------------------------------------------------------
    # Triggerer
    # --------------------------------------------------------
    triggerer_cpu       = optional(number, 0.5)
    triggerer_memory_gb = optional(number, 0.5)
    triggerer_count     = optional(number, 1)

    # --------------------------------------------------------
    # Web Server
    # --------------------------------------------------------
    web_server_cpu        = optional(number, 0.5)
    web_server_memory_gb  = optional(number, 1.875)
    web_server_storage_gb = optional(number, 1)

    # --------------------------------------------------------
    # Workers
    # --------------------------------------------------------
    worker_cpu        = optional(number, 0.5)
    worker_memory_gb  = optional(number, 1.875)
    worker_storage_gb = optional(number, 1)
    worker_min_count  = optional(number, 1)
    worker_max_count  = optional(number, 3)

    # --------------------------------------------------------
    # IAM - roles para a SA do Composer
    # --------------------------------------------------------
    sa_roles = optional(list(string), [
      "roles/composer.worker",
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/storage.objectAdmin",
    ])

    # --------------------------------------------------------
    # Airflow - configurações e variáveis
    # --------------------------------------------------------
    airflow_config_overrides = optional(map(string), {})
    env_variables            = optional(map(string), {})
    pypi_packages            = optional(map(string), {})

    # Senhas/credenciais geradas pelo Terraform e salvas no Secret Manager.
    # Apenas para segredos cujo ciclo de vida é 100% controlado pelo Terraform
    # (ex: db_password de banco interno). Segredos externos (tokens de API,
    # chaves de terceiros) devem ser gerenciados fora do módulo.
    generated_secrets = optional(map(object({
      length  = optional(number, 32)
      special = optional(bool, true)
    })), {})

    # --------------------------------------------------------
    # Recursos opcionais
    # --------------------------------------------------------
    enable_data_lineage          = optional(bool, false)
    kms_key_name                 = optional(string, null)
    task_logs_retention_days     = optional(number, 30)

    # --------------------------------------------------------
    # Maintenance Window
    # --------------------------------------------------------
    maintenance_window = optional(object({
      start_time = string # Ex: "2024-01-01T06:00:00Z"
      end_time   = string # Ex: "2024-01-01T10:00:00Z"
      recurrence = string # Ex: "FREQ=WEEKLY;BYDAY=SA,SU"
    }), null)

    # --------------------------------------------------------
    # Labels
    # --------------------------------------------------------
    labels = optional(map(string), {})
  }))
}
