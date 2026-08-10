variable "worker_pool_settings" {
  description = <<-EOT
    Mapa de configuração dos Cloud Build Private Worker Pools a serem criados.
    A chave do mapa identifica logicamente o pool (ex.: "modelagem", "inferencia").
  EOT
  type = map(object({
    sigla      = string
    project_id = string
    location   = string

    # Rede privada (VPC peering) onde os workers do Cloud Build serão provisionados
    network_project_id      = string
    network_name            = string # nome da VPC (peered_network = projects/{network_project_id}/global/networks/{network_name})
    peered_network_ip_range = optional(string, "/29")

    # Dimensionamento dos workers
    machine_type   = optional(string, "e2-medium")
    disk_size_gb   = optional(number, 100)
    no_external_ip = optional(bool, true)

    # Projetos/principals externos autorizados a usar o pool (roles/cloudbuild.workerPoolUser)
    # Padrão aditivo, pois o consumo é feito por outros projetos/pipelines (ex.: spoke-modelagem)
    worker_pool_users = optional(list(string), [])

    annotations = optional(map(string), {})
  }))
}
