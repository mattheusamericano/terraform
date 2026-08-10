# ============================================================
# Cloud Composer 3 - Variables
# ============================================================

variable "composer_settings" {
  description = "Mapa de configurações dos ambientes Cloud Composer 3"
  type = map(object({
    # --------------------------------------------------------
    # Identificação
    # --------------------------------------------------------
    project_id              = string
    network_project_id      = string 
    sigla                   = string
    region                  = string

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
    triggerer_cpu       = optional(number, 1)
    triggerer_memory_gb = optional(number, 1)
    triggerer_count     = optional(number, 1)

    # --------------------------------------------------------
    # Web Server
    # --------------------------------------------------------
    web_server_cpu        = optional(number, 0.5)
    web_server_memory_gb  = optional(number, 2)
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
      "roles/secretmanager.secretAccessor"
    ])

    # --------------------------------------------------------
    # Airflow - configurações e variáveis
    # --------------------------------------------------------
    airflow_config_overrides = optional(map(string), {})
    pypi_packages            = optional(map(string), {})

    # --------------------------------------------------------
    # Recursos opcionais
    # --------------------------------------------------------
    enable_data_lineage          = optional(bool, false)
    kms_project_id               = optional(string, null)
    key_ring                     = optional(string, null)
    key_crypto                   = optional(string, null)
    # --------------------------------------------------------
    # Maintenance Window
    # --------------------------------------------------------
    maintenance_window = optional(object({
      start_time = string # Ex: "2024-01-01T06:00:00Z"
      end_time   = string #0 Ex: "2024-01-01T10:00:0Z"
      recurrence = string # Ex: "FREQ=WEEKLY;BYDAY=SA,SU"
    }), null)

    # --------------------------------------------------------
    # Labels
    # --------------------------------------------------------
    labels = optional(map(string), {})
  }))
}

#Variavel fora do bloco map object
variable "project_id" {
  type = string  
}

variable "network_project_id" {
  type = string  
}