workbench_settings = {
  "wb-01" = {
    project_id                = "prj-modelagem-des"
    region                    = "us-central1"
    zone                      = "c"
    sigla                     = "sqa"
    network_project_id        = "prj-network-services-prd-cef"
    kms_project_id            = "prj-hsm-services-prd"
    workbench_machine_type    = "n1-standard-4"
    workbench_disk_size_gb    = "150"
    workbench_disk_type       = "PD_BALANCED"
    workbench_disk_encryption = "CMEK"
    key_ring                  = "workbhsmNPRDring"
    key_crypto                = "workbNPRDSYMAES256hsm001"
    name_vpc_shared           = "vpc-shared"
    name_subnet_vpc_shared    = "subnet-shared-us-central1"
    sa_account_id             = "sa-wb-01-sqa-des"
    auto_shutdown             = "3600"

    labels = {
      ambiente = "desenvolvimento"
    }

    # sem project_roles: usa o conjunto padrão do módulo (12 roles) — informe
    # uma lista aqui só se quiser SUBSTITUIR esse padrão inteiro

    # roles adicionais no próprio projeto, além do conjunto padrão
    extra_project_roles = [
      "roles/secretmanager.secretAccessor",
    ]

    # sem cross_project_roles: usa o default do módulo (bigquery.dataViewer em
    # bigdata-1744049006). Descomente pra manter esse grant e somar outro:
    # cross_project_roles = [
    #   { project_id = "bigdata-1744049006", role = "roles/bigquery.dataViewer" },
    #   { project_id = "prj-outro-compartilhado", role = "roles/storage.objectViewer" },
    # ]
  }

  "wb-02-gpu" = {
    project_id                = "prj-modelagem-des"
    region                    = "us-central1"
    zone                      = "c"
    sigla                     = "sqa"
    network_project_id        = "prj-network-services-prd-cef"
    kms_project_id            = "prj-hsm-services-prd"
    workbench_machine_type    = "n1-standard-8"
    workbench_disk_size_gb    = "250"
    workbench_disk_type       = "PD_BALANCED"
    workbench_disk_encryption = "CMEK"
    key_ring                  = "workbhsmNPRDring"
    key_crypto                = "workbNPRDSYMAES256hsm001"
    name_vpc_shared           = "vpc-shared"
    name_subnet_vpc_shared    = "subnet-shared-us-central1"
    sa_account_id             = "sa-wb-02-sqa-des"
    auto_shutdown             = "7200"

    # instância com GPU, consumindo uma reserva específica do Compute Engine
    wbrv_accelerator_type  = "NVIDIA_TESLA_T4"
    wbrv_accelerator_count = 1
    wb_reservation_name    = "reserva-gpu-modelagem"

    labels = {
      ambiente = "desenvolvimento"
      workload = "gpu"
    }
  }
}
