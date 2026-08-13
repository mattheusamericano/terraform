variable "worker_pool_settings" {
  description = <<-EOT
    Mapa de configuração dos Cloud Build Private Worker Pools a serem criados.
    A chave do mapa identifica logicamente o pool (ex.: "modelagem", "inferencia").
    A service account dedicada do Cloud Build vem embutida em `service_account`,
    para que o módulo inteiro seja orientado por um único `for_each`.
  EOT
  type = map(object({
    sigla      = string
    project_id = string
    location   = string

    # Rede privada (VPC peering) onde os workers do Cloud Build serão provisionados
    network_project_id = string
    network_name        = string # nome da VPC (peered_network = projects/{network_project_id}/global/networks/{network_name})

    # CIDR /29 explícito dentro do range já reservado via Private Services Access.
    # Deixe null (padrão) para o Cloud Build alocar automaticamente.
    peered_network_ip_range = optional(string, null)

    # Dimensionamento dos workers
    machine_type   = optional(string, "e2-medium")
    disk_size_gb   = optional(number, 100)
    no_external_ip = optional(bool, true)

    # Projetos/principals externos autorizados a usar o pool (roles/cloudbuild.workerPoolUser)
    # Padrão aditivo, pois o consumo é feito por outros projetos/pipelines (ex.: spoke-modelagem)
    worker_pool_users = optional(list(string), [])

    annotations = optional(map(string), {})

    # Service account dedicada do Cloud Build para este pool (usada em `service_account`
    # do trigger/build). `roles` é a lista completa e customizável de papéis concedidos
    # no mesmo `project_id` do pool — ajuste por projeto/pipeline conforme o que o build
    # efetivamente precisa (BigQuery, Storage, Artifact Registry etc.).
    service_account = optional(object({
      display_name = optional(string, "SA do Cloud Build - gerenciada via Terraform")
      roles = optional(list(string), [
        "roles/bigquery.jobUser",
        "roles/bigquery.user",
        "roles/storage.objectAdmin",
      ])
    }), {})
  }))
}
