####################
#OPTIONAL RESOURCES#
####################
enabled_pubsub              = __enabled_pubsub__
enabled_workbench           = __enabled_workbench__
enabled_bucket              = __enabled_bucket__
enabled_dataform_repo       = __enabled_dataform_repo__
enabled_sql                 = __enabled_sql__
enabled_bq_dataset          = __enabled_bq_dataset__
enabled_firestore           = __enabled_firestore__
enabled_gke                 = __enabled_gke__
enabled_wipool              = __enabled_wipool__
enabled_airflow_composer   = __enabled_airflow_composer__
enabled_colab_rt_template   = __enabled_colab_rt_template__
#
#WORKBENCH
#
workbench_settings = {
    #1
    "wb-01" = {
        project_id                  = "__project_id__"
        region                      = "__region__"
        zone                        = "c"
        sigla                       = "__sigla__"
        network_project_id          = "prj-network-services-__environment__-cef"
        sa_account_id               = "sa-wb-01-__sigla__-__environment__" # Ao criar novo label de workbanck alterar a SA junto com mesmo label.
        kms_project_id              = "prj-hsm-services-__environment__"
        key_ring                    = "workbhsmNPRDring"
        key_crypto                  = "workbNPRDSYMAES256hsm001"
        workbench_machine_type      = "__workbench_machine_type__"
        workbench_disk_size_gb      = "__workbench_disk_size_gb__"
        workbench_disk_type         = "__workbench_disk_type__"
        workbench_disk_encryption   = "CMEK"
        name_vpc_shared             = "__name_vpc_shared__"
        name_subnet_vpc_shared      = "__name_vpc_subnet__"
        repository_name             = "acr-__sigla__-__environment__"

        #wbrv_machine_type           = "__workbench_machine_type__"
        #wbrv_accelerator_type       = "NVIDIA_TESLA_T4"
        #wbrv_accelerator_count      = 1
    }

    #1
    "wb-02" = {
        project_id                  = "__project_id__"
        region                      = "__region__"
        zone                        = "c"
        sigla                       = "__sigla__"
        network_project_id          = "prj-network-services-__environment__-cef"
        sa_account_id               = "sa-wb-02-__sigla__-__environment__" # Ao criar novo label de workbanck alterar a SA junto com mesmo label.
        kms_project_id              = "prj-hsm-services-__environment__"
        key_ring                    = "workbhsmNPRDring"
        key_crypto                  = "workbNPRDSYMAES256hsm001"
        workbench_machine_type      = "__workbench_machine_type__"
        workbench_disk_size_gb      = "__workbench_disk_size_gb__"
        workbench_disk_type         = "__workbench_disk_type__"
        workbench_disk_encryption   = "CMEK"
        name_vpc_shared             = "__name_vpc_shared__"
        name_subnet_vpc_shared      = "__name_vpc_subnet__"
        repository_name             = "acr-__sigla__-__environment__"

        #wbrv_machine_type           = "__workbench_machine_type__"
        #wbrv_accelerator_type       = "NVIDIA_TESLA_T4"
        #wbrv_accelerator_count      = 1
    }

}
    
#
#ARTIFACT_REGISTRY
#
artifact_registry_settings = {

    #1
    "acr" = {
        project_id                  = "__project_id__"
        region                      = "__region__"
        artifact_format             = "PYTHON"
        artifact_mode               = "STANDARD_REPOSITORY"
        sigla                       = "__sigla__"
    }

}

#
#PUB_SUB
#
pubsub_topic_settings = {
    #1
    "pst" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
    }

}
pubsub_settings = {
    #1
    "pss" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        topic_name                  = "pst-__sigla__-__environment__"
        ack_deadline_seconds        = 20
        message_retention_duration  = "1200s"
        retain_acked_messages       = true
    }

}

#
#BUCKET_OBJECT
#
bucket_settings = {
    #1
    "bucket-data" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        storage_class               = "STANDARD"
        kms_key_name                = "BuckethsmPRDring"
        kms_key_crypto              = "BucketPRDSYMAES256hsm001"
        kms_project_id              = "prj-hsm-services-__environment__"
    }
    #2
    "bucket-logs" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        storage_class               = "STANDARD"
        kms_key_name                = "BuckethsmPRDring"
        kms_key_crypto              = "BucketPRDSYMAES256hsm001"
        kms_project_id              = "prj-hsm-services-__environment__"
    }
}

#
#DATAFORM_REPOSITORY
#
dataform_repository_settings = {
    #1
    "df-repo" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        service_account_id          = "sa-df-__sigla__-__environment__"
    }
}

#
#CLOUD_SQL
#
cloud_sql_instance_settings = {
    #1
    "sql" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        tier                        = "__sql_tier__"
        database_version            = "__sql_database_version__"
        disk_type                   = "__sql_disk_type__"
        disk_size                   = "__sql_disk_size__"
#        disk_autoresize_limit       = "__sql_disk_autoresize_limit__"
        network_project_id          = "prj-network-services-prd-cef"
        name_vpc_shared             = "__name_vpc_shared__"
        key_ring                    = "infrahsmNPRDring"
        key_crypto                  = "infraNPRDSYMAES256hsm001"
        kms_project_id              = "prj-hsm-services-__environment__"
        group_users                 = "__sql_group_users__"

    }
}

#
#CLOUD_SQL_DATABASE
#
cloud_sql_database_settings = {
    #1
    "sqldb" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        instance_name               = "sql-__sigla__-__environment__"

    }
}

#
#BIGQUERY_DATASET
#
bq_dataset_settings = {
    #1
    "bq_dataset" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        sa_name                     = "bq-dataset"
        group_writer                = "__group_bq_dataset_writer__"
    }
}

#
#Firestore_Database
# 
firestore_settings = {
    #1
    "frs-db" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        type                        = "__firestore_type__"
        group_writer                = "__firestore_group_writer__"
    }
}

#
#GKE
#

gke_cluster_settings = {
    #1
    "gke" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        zone                        = "b"
        network_project_id          = "prj-network-services-__environment__-cef"
        name_vpc_shared             = "__name_vpc_shared__"
        subnet_name                 = "__name_vpc_subnet__"
        master_ipv4_cidr_block      = "172.16.0.0/28"
        pods_range_name             = "pods-__sigla__-__environment__"
        pods_cidr                   = "10.1.0.0/16"
        services_range_name         = "services-__sigla__-__environment__"
        services_cidr               = "10.2.0.0/20"
        system_min_node_count       = "__gke_system_min_node_count__"
        system_max_node_count       = "__gke_system_max_node_count__"
        system_machine_type         = "__gke_system_machine_type__"
    }

}

#
#GKE_NODEPOOL
#
gke_nodepool_settings = {
    #1
    "apptfdes" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        zone                        = "b"
        cluster_name                = "gke-__sigla__-__environment__"
        gke_sa_email                = "sa-gke-__sigla__-__environment__@__project_id__.iam.gserviceaccount.com"

        machine_type                = "__gke_machine_type__"
        disk_type                   = "__gke_disk_type__"
        disk_size_gb                = "__gke_disk_size__"

        min_node_count              = "__gke_min_node_count__"
        max_node_count              = "__gke_max_node_count__"

        taint_value                 = "appterraform"
    }
}

#
#Workload_Identity_Pool
#
wipool_settings = {
    #1
    "wipool-github" = {
        project_id              = "__project_id__"
        wipool_display_name     = "Wipool GitHub"
        wipool_provider_id      = "github-provider"
        wipool_sa_account_id    = "sa-wipool-git-__sigla__-__environment__"
        wipool_issuer_uri       = "https://token.actions.githubusercontent.com"
        attribute_condition     = "attribute.repository_owner == \"caixagithub\""
        repository_owner        = "caixagithub"

        attribute_mapping       = {
            "google.subject"             = "assertion.sub"
            "attribute.actor"            = "assertion.actor"
            "attribute.aud"              = "assertion.aud"
            "attribute.repository"       = "assertion.repository"
            "attribute.repository_owner" = "assertion.repository_owner"     
        }
        

    }
}

#
# Composer Airflow
#

composer_settings = {
  "airflow" = {
    project_id              = "__project_id__"
    network_project_id      = "prj-network-services-__environment__-cef"
    sigla                   = "__sigla__"
    region                  = "__region__"

    # Imagem
    image_version           = "__composer_image_version__"

    # Rede (Shared VPC)
    network_name            = "__name_vpc_shared__"
    subnetwork_name         = "__name_vpc_subnet__"
    pods_ip_range_name      = "pods-composer-range"
    services_ip_range_name  = "services-composer-range"

    # Tamanho (pequeno para dev/hml, médio/grande para prd)
    environment_size = "__composer_environment_size__"

    # Scheduler
    scheduler_cpu        = 1
    scheduler_memory_gb  = 2
    scheduler_storage_gb = 1
    scheduler_count      = 1

    # Workers
    worker_cpu        = 1
    worker_memory_gb  = 2
    worker_storage_gb = 1
    worker_min_count  = "__composer_worker_min_count__"
    worker_max_count  = "__composer_worker_max_count__"

    # IAM - roles extras além dos defaults
    sa_roles = [
      "roles/composer.worker",
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/storage.objectAdmin",
      "roles/dataflow.developer",
      "roles/iam.serviceAccountUser",
    ]

    # Airflow config overrides
    airflow_config_overrides = {
      "core-parallelism"      = "32"
      "core-max_active_runs_per_dag" = "5"
      "scheduler-min_file_process_interval" = "30"
    }

    # Pacotes Python extras
    pypi_packages = {
      "apache-airflow-providers-google" = ">=10.0.0"
      "pandas"                          = ">=2.0.0"
    }
    # Janela de Manutenção
    maintenance_window ={
        start_time  = "2023-01-01T01:00:00Z"
        end_time    = "2023-01-01T07:00:00Z"
        recurrence  = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
    # KMS
    kms_project_id = "prj-hsm-services-__environment__"
    key_ring       = "airflowhsmNPRDring"
    key_crypto     = "airflwNPRDSYMAES256hsm001"
  }
}

#
#PROJECT_SERVICES
#
        project_id                  = "__project_id__"
        network_project_id          = "prj-network-services-__environment__-cef"

#
#COLAB_RUNTIME_TEMPLATE
#
colab_runtime_template_settings = {
    #1
    "colab-rtemplate-gpu" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        machine_type                = "__rt_machine_type__"
        accelerator_type            = "__rt_accelerator_type__"
        accelerator_count           = "__rt_accelerator_count__"
        disk_type                   = "__rt_disk_type__"
        disk_size_gb                = "__rt_disk_size_gb__"
        network_project_id          = "prj-network-services-__environment__-cef"
        name_vpc_shared             = "__name_vpc_shared__"
        name_subnet_vpc_shared      = "__name_vpc_subnet__"
    }
    
    #2
    "colab-rtemplate" = {
        project_id                  = "__project_id__"
        sigla                       = "__sigla__"
        region                      = "__region__"
        machine_type                = "__rt_machine_type__"
        disk_type                   = "__rt_disk_type__"
        disk_size_gb                = "__rt_disk_size_gb__"
        network_project_id          = "prj-network-services-__environment__-cef"
        name_vpc_shared             = "__name_vpc_shared__"
        name_subnet_vpc_shared      = "__name_vpc_subnet__"     
    }

}