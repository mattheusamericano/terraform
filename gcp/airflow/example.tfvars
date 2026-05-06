# ============================================================
# Exemplo de uso - composer.tfvars
# ============================================================

composer_settings = {
  "pipeline-dados" = {
    project_id      = "meu-projeto-12345"
    host_project_id = "meu-host-vpc-projeto"
    sigla           = "dpipe"
    region          = "us-central1"

    # Imagem
    image_version = "composer-3-airflow-2.9"

    # Rede (Shared VPC)
    network_name           = "vpc-shared"
    subnetwork_name        = "subnet-composer-us-central1"
    pods_ip_range_name     = "pods-composer-range"
    services_ip_range_name = "services-composer-range"
    enable_private_endpoint = true

    # Tamanho (pequeno para dev/hml, médio/grande para prd)
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    # Scheduler
    scheduler_cpu        = 1
    scheduler_memory_gb  = 2
    scheduler_storage_gb = 1
    scheduler_count      = 1

    # Workers
    worker_cpu        = 1
    worker_memory_gb  = 2
    worker_storage_gb = 1
    worker_min_count  = 1
    worker_max_count  = 4

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

    # Variáveis de ambiente não sensíveis
    env_variables = {
      "GCP_PROJECT"  = "meu-projeto-12345"
      "GCP_REGION"   = "us-central1"
      "ENVIRONMENT"  = "dev" # ou hml / prd via workspace
    }

    # Pacotes Python extras
    pypi_packages = {
      "apache-airflow-providers-google" = ">=10.0.0"
      "pandas"                          = ">=2.0.0"
    }

    # Segredos gerados pelo Terraform -> Secret Manager
    # O valor é gerado via random_password; nunca passa pelo tfvars.
    # Segredos externos (tokens de API, chaves de terceiros) NÃO entram aqui.
    generated_secrets = {
      "db_password" = {
        length  = 32
        special = true
      }
      "internal_api_key" = {
        length  = 48
        special = false # Apenas alfanumérico, para sistemas que não aceitam especiais
      }
    }

    # Retenção de logs de tasks
    task_logs_retention_days = 30

    # Maintenance window (sábado e domingo de madrugada)
    maintenance_window = {
      start_time = "2024-01-01T03:00:00Z"
      end_time   = "2024-01-01T07:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }

    labels = {
      team        = "data-engineering"
      cost_center = "dados"
    }
  }
}
