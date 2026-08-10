variable "enabled_pubsub" {
  type    = bool
  default = false
}

variable "enabled_workbench" {
  type    = bool
  default = false
}

variable "enabled_bucket" {
  type    = bool
  default = false
}

variable "enabled_dataform_repo" {
  type    = bool
  default = false
}

variable "enabled_sql" {
  type    = bool
  default = false
}

variable "enabled_bq_dataset" {
  type    = bool
  default = false
}

variable "enabled_firestore" {
  type    = bool
  default = false
}

variable "enabled_gke" {
  type    = bool
  default = false
}

variable "enabled_wipool" {
  type    = bool
  default = false
}

variable "enabled_airflow_composer" {
  type    = bool
  default = false
}

variable "enabled_colab_rt_template" {
  type    = bool
  default = false
}

variable "enabled_dataproc_cluster" {
  type    = bool
  default = false
}

variable "enabled_dataproc_session_template" {
  type    = bool
  default = false
}

variable "enabled_cloudbuild_worker_pool" {
  type    = bool
  default = false
}



#
#WORKBENCH
#
variable "workbench_settings"{
  description = "Workbench Settings"
  type = map(object({
    project_id                          = string
    region                              = string
    zone                                = string
    sigla                               = string
    network_project_id                  = string  
    kms_project_id                      = string
    sa_account_id                       = string
    workbench_machine_type              = string
    workbench_disk_size_gb              = string
    workbench_disk_type                 = string
    workbench_disk_encryption           = string
    key_ring                            = string
    key_crypto                          = string 
    name_vpc_shared                     = string
    name_subnet_vpc_shared              = string
    repository_name                     = string

    wb_reservation_enabled              = optional(bool, false)
    wbrv_machine_type                   = optional(string)
    wbrv_accelerator_type               = optional(string)
    wbrv_accelerator_count              = optional(number)
    }))
}



#
#ARTIFACT_REGISTRY
#
variable "artifact_registry_settings"{
  type = map(object({
    project_id                          = string
    region                              = string
    artifact_format                     = string  
    artifact_mode                       = string
    cleanup_policy_dry_run              = optional(bool, true)
    sigla                               = string
    
    }))
}

#
#PUB_SUB
#
variable "pubsub_topic_settings"{
    type = map(object({
        project_id              = string
        sigla                   = string
    }))
}
variable "pubsub_settings"{
    type = map(object({
        project_id                      = string
        topic_name                      = string
        ack_deadline_seconds            = number
        message_retention_duration      = string
        retain_acked_messages           = optional(bool, true)
        sigla                           = string
    }))
}

#
#BUCKET_OBJECT
#
variable "bucket_settings" {
  type = map(object({
    project_id                  = string
    sigla                       = string
    region                      = string
    storage_class               = string
    kms_key_name                = string
    kms_project_id              = string
    kms_key_crypto              = string
  }))
}

variable "dataform_repository_settings" {
    type = map(object({
        project_id                  = string
        region                      = string
        sigla                       = string
        service_account_id          = string
        git_url                     = optional(string)
        git_default_branch          = optional(string)
        git_secret_version          = optional(string)
        kms_project_id              = string
        key_ring                    = string
        key_crypto                  = string
    }))
}

#
#CLOUD_SQL
#
variable "cloud_sql_instance_settings" {
    type = map(object({
        project_id                  = string
        region                      = string
        sigla                       = string
        tier                        = string
        database_version            = string
        disk_type                   = string
        disk_size                   = number
        disk_autoresize_limit       = optional(number)
        network_project_id          = string
        name_vpc_shared             = string
        key_ring                    = string
        key_crypto                  = string
        kms_project_id              = string
        group_users                 = string
    }))
}

#
#CLOUD_SQL_DATABASE
#
variable "cloud_sql_database_settings" {
    type = map(object({
        project_id                  = string
        sigla                       = string
        instance_name               = string
    }))
}

#
#BIGQUERY_DATASET
#
variable "bq_dataset_settings" {
  type = map(object({
    project_id    = string
    sigla         = string
    region        = string
    sa_name       = string
    group_writer  = string 
    description   = optional(string, "Dataset created by Terraform")

    default_table_expiration_ms     = optional(number, null)
    default_partition_expiration_ms = optional(number, null)

    # KMS
    kms_project_id = optional(string, null)
    key_ring       = optional(string, null)
    key_crypto     = optional(string, null)
    kms_key        = optional(string, null)

  }))
}

#
#Firestore_Database
# 
variable "firestore_settings" {
  type = map(object({
    project_id          = string
    region              = string
    sigla               = string
    type                = optional(string, "FIRESTORE_NATIVE")
    kms_project_id      = optional(string, null)
    kms_keyring         = optional(string, null)
    kms_crypto          = optional(string, null)
    group_writer        = string
    group_reader        = optional(string)
  }))

}

#
#GKE
#

variable "gke_cluster_settings" {
  type = map(object({
    project_id  = string
    region      = string
    zone        = optional(string)
    sigla       = string

    # Networking
    network_project_id      = string
    name_vpc_shared         = string
    subnet_name             = string
    master_ipv4_cidr_block  = string      # ex: "172.16.0.0/28"
    pods_range_name         = string       # nome do secondary range para pods "192.168.0.0/16"
    services_range_name     = string       # nome do secondary range para services "10.245.0.0/22"
    pods_cidr               = string
    services_cidr           = string

    #System Nodepool
    system_min_node_count   = number
    system_max_node_count   = number
    system_machine_type     = string

    # Master authorized networks
    master_authorized_networks = optional(list(object({
      name = string
      cidr = string
    })), [])

    # KMS (opcional)
    kms_project_id    = optional(string, null)
    kms_keyring       = optional(string, null)
    kms_crypto        = optional(string, null)
  }))
}

#
#GKE_NODEPOOL
#
variable "gke_nodepool_settings" {
  type = map(object({
    project_id   = string
    region       = string
    zone         = string
    sigla        = string
    cluster_name = string   # output do módulo cluster
    gke_sa_email = string   # output do módulo cluster (gke_sa_emails)

    machine_type = optional(string, "e2-standard-4")
    disk_type    = optional(string, "pd-ssd")
    disk_size_gb = optional(number, 100)

    min_node_count = optional(number, 1)
    max_node_count = optional(number, 2)

    taint_value    = string

  }))
}

variable "wipool_settings" {
    type = map(object({
        project_id              = string
        wipool_display_name     = string
        wipool_provider_id      = string
        attribute_condition     = string
        wipool_issuer_uri       = string
        repository_owner        = string
        wipool_sa_account_id    = string
        attribute_mapping       = optional(map(string))
    }))

}

# ============================================================
# Cloud Composer 3 - Variables
# ============================================================

variable "composer_settings" {
  description = "Mapa de configurações dos ambientes Cloud Composer 3"
  type = map(object({
    project_id                = string
    network_project_id        = string 
    sigla                     = string
    region                    = string
    airflow_config_overrides  = optional(map(string), {})
    pypi_packages             = optional(map(string), {})
    enable_data_lineage       = optional(bool, false)
    kms_project_id            = optional(string, null)
    key_ring                  = optional(string, null)
    key_crypto                = optional(string, null)
    image_version             = optional(string, "composer-3-airflow-2.9")
    network_name              = string
    subnetwork_name           = string
    pods_ip_range_name        = string
    services_ip_range_name    = string
    environment_size          = optional(string, "ENVIRONMENT_SIZE_SMALL")
    scheduler_cpu             = optional(number, 0.5)
    scheduler_memory_gb       = optional(number, 1.875)
    scheduler_storage_gb      = optional(number, 1)
    scheduler_count           = optional(number, 1)

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

    maintenance_window = optional(object({
      start_time = string # Ex: "2099-01-01T06:00:00Z OBS A data é ignorada pela API"
      end_time   = string #0 Ex: "2099-01-01T10:00:0Z"
      recurrence = string # Ex: "FREQ=WEEKLY;BYDAY=SA,SU"
    }), null)

  }))
}

#
#COLAB_RUNTIME_TEMPLATE
#
variable "colab_runtime_template_settings" {
  type = map(object({
    project_id                          = string
    region                              = string
    sigla                               = string
    machine_type                        = string
    accelerator_type                    = optional(string)
    accelerator_count                   = optional(string)
    disk_type                           = string
    disk_size_gb                        = number
    network_project_id                  = string
    name_vpc_shared                     = string
    name_subnet_vpc_shared              = string
    runtime_user                        = optional(string)
    runtime_name                        = optional(string)

  }))
}
variable "enabled_cloud_run" {
  type    = bool
  default = false
}

#
# CLOUD_RUN
#
variable "cloud_run_settings" {
  type = map(object({
    project_id    = string
    region        = string
    sigla         = string
    image         = string
    cpu           = string
    memory        = string
    max_scale     = number
    vpc_connector = optional(string)
    invoker       = optional(string, "allUsers")
    sa_account_id = string
    network_project_id     = optional(string)
    name_subnet_vpc_shared = optional(string)
    kms_project_id = optional(string, null)
    key_ring       = optional(string, null)
    key_crypto     = optional(string, null)
  }))
}

#
#DATAPROC_CLUSTER
#
variable "dataproc_cluster_settings" {
  description = "Mapa de definições de clusters Dataproc (HDI/Spark), uma entrada por cluster a provisionar."
  type = map(object({
    sigla                             = string
    project_id                        = string
    region                            = string
    zone                              = optional(string)
    subnetwork                        = string
    internal_ip_only                  = optional(bool, true)
    tags                              = optional(list(string), [])
    image_version                     = optional(string, "2.3-debian12")
    optional_components               = optional(list(string), ["JUPYTER"])
    enable_component_gateway          = optional(bool, true)
    override_properties               = optional(map(string), {})
    autoscaling_policy_uri            = optional(string)
    staging_bucket                    = optional(string)
    labels                            = optional(map(string), {})
    service_account_display_name      = optional(string)
    service_account_description       = optional(string, "Service Account do cluster Dataproc")
    service_account_scopes            = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    engine                            = optional(string, "DEFAULT")
    # IAM - roles/dataproc.viewer + roles/dataproc.editor para a própria SA no próprio projeto
    grant_self_project_dataproc_roles = optional(bool, true)
    shared_vpc_host_project           = optional(string)
    iam_propagation_wait              = optional(string, "60s")

    master_settings = optional(object({
      machine_type      = optional(string, "n4-standard-2")
      boot_disk_type     = optional(string, "hyperdisk-balanced")
      boot_disk_size_gb  = optional(number, 100)
      num_instances      = optional(number, 1)
    }), {})

    worker_settings = optional(object({
      machine_type      = optional(string, "n4-standard-2")
      boot_disk_type     = optional(string, "hyperdisk-balanced")
      boot_disk_size_gb  = optional(number, 200)
      num_instances      = optional(number, 2)
    }), {})
    
    # Bindings adicionais livres (ex.: roles/dataproc.worker para SA em outro projeto)
    additional_project_bindings = optional(map(object({
      project_id = string
      role       = string
      member     = string
    })), {})
  }))
}

#
#DATAPROC_SESSION_TEMPLATE
#
variable "dataproc_session_template_settings" {
  description = "Mapa de definições de Dataproc Serverless Session Templates (sessões interativas Jupyter/Spark Connect)."
  type = map(object({
    sigla                         = string
    project_id                    = string
    location                      = string
    labels                        = optional(map(string), {})
    grant_kms_encrypter_decrypter = optional(bool, false)
    shared_vpc_host_project       = optional(string)
    iam_propagation_wait          = optional(string, "60s")
    # "jupyter" ou "spark_connect"
    session_type                  = optional(string, "jupyter")

    jupyter_settings = optional(object({
      kernel       = optional(string, "PYTHON") # PYTHON | SCALA
      display_name = optional(string)
    }), {})

    runtime_settings = optional(object({
      version         = optional(string)
      container_image = optional(string)
      properties      = optional(map(string), {})
    }), {})

    execution_settings = object({
      service_account = string
      subnetwork_uri  = string
      staging_bucket  = optional(string)
      network_tags    = optional(list(string), [])
      kms_key         = optional(string)
      ttl             = optional(string)
      idle_ttl        = optional(string, "3600s")
      # SERVICE_ACCOUNT | END_USER_CREDENTIALS
      auth_type       = optional(string, "SERVICE_ACCOUNT")
    })

    peripherals_settings = optional(object({
      metastore_service               = optional(string)
      spark_history_dataproc_cluster  = optional(string)
    }), {})
  }))
}
#
#CLOUDBUILD_WORKER_POOL
#
variable "worker_pool_settings" {
  type = map(object({
    sigla                   = string
    project_id              = string
    location                = string
    network_project_id      = string
    network_name            = string # nome da VPC (peered_network = projects/{network_project_id}/global/networks/{network_name})
    peered_network_ip_range = optional(string)
    machine_type            = optional(string, "e2-medium")
    disk_size_gb            = optional(number, 100)
    no_external_ip          = optional(bool, true)

    # Projetos/principals externos autorizados a usar o pool (roles/cloudbuild.workerPoolUser)
    # Padrão aditivo, pois o consumo é feito por outros projetos/pipelines (ex.: spoke-modelagem)
    worker_pool_users = optional(list(string), [])
    annotations       = optional(map(string), {})
  }))
}

#
#PROJECT_SERVICES
#
variable "project_id" {
  type = string
}
variable "network_project_id" {
  type = string  
}