variable "dataproc_session_template_settings" {
  description = "Mapa de definições de Dataproc Serverless Session Templates (sessões interativas Jupyter/Spark Connect)."
  type = map(object({
    sigla      = string
    project_id = string
    location   = string

    # "jupyter" ou "spark_connect"
    session_type = optional(string, "jupyter")

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

    labels = optional(map(string), {})

    # Quando kms_key é usado, concede roles/cloudkms.cryptoKeyEncrypterDecrypter
    # ao service agent do Dataproc do project_id sobre a chave (padrão aditivo,
    # já que a chave normalmente pertence a outro projeto)
    grant_kms_encrypter_decrypter = optional(bool, false)

    # VPC compartilhada - concede roles/compute.networkUser no host project da subnet
    # (execution_settings.subnetwork_uri) tanto para a SA de execução quanto para o
    # Dataproc Service Agent (service-<num>@dataproc-accounts...), que também é usado
    # pelo Dataproc Serverless. Sem isso a criação falha por falta de permissão na subnet.
    shared_vpc_host_project = optional(string)

    # Tempo de espera após os bindings de IAM antes de criar o session template.
    iam_propagation_wait = optional(string, "60s")
  }))
}
