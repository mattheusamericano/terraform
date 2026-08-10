dataproc_session_template_settings = {
  "01" = {
    sigla      = "pub"
    project_id = "prj-publisher-poc"
    location   = "southamerica-east1"

    session_type = "jupyter"

    jupyter_settings = {
      kernel       = "PYTHON"
      display_name = "Jupyter Session - Publisher POC"
    }

    runtime_settings = {
      version    = "2.3"
      properties = {
        "spark.dynamicAllocation.enabled" = "false"
        "spark.executor.instances"        = "2"
      }
    }

    execution_settings = {
      # este módulo não cria SA própria (diferente do dataproc-cluster); use aqui o
      # output "cluster_service_accounts" do módulo dataproc-cluster se quiser reaproveitar
      # a SA do cluster, ou informe outra SA de sua escolha
      service_account = "sa-dp-01-pub-des@prj-publisher-poc.iam.gserviceaccount.com"
      subnetwork_uri  = "projects/prj-network-services-des-cef/regions/southamerica-east1/subnetworks/sub-poc-des"
      idle_ttl        = "3600s"
      ttl              = "86400s"
      auth_type        = "SERVICE_ACCOUNT"
    }

    peripherals_settings = {
      spark_history_dataproc_cluster = "projects/prj-publisher-poc/regions/southamerica-east1/clusters/dp-01-pub-des"
    }

    # subnetwork_uri está em prj-network-services-des-cef (VPC compartilhada) -
    # sem isso, a criação falha por falta de permissão na subnet
    shared_vpc_host_project = "prj-network-services-des-cef"

    labels = {
      ambiente = "des"
    }
  }
}
