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

    network_project_id = string
    network_name       = string

    peered_network_ip_range = optional(string, null)

    machine_type   = optional(string, "e2-medium")
    disk_size_gb   = optional(number, 100)
    no_external_ip = optional(bool, true)

    worker_pool_users = optional(list(string), [])

    annotations = optional(map(string), {})

    kms_project_id = optional(string, null)
    kms_key_ring   = optional(string, null)
    kms_crypto_key = optional(string, null)

    service_account = optional(object({
      display_name = optional(string, "SA do Cloud Build - gerenciada via Terraform")
      roles = optional(list(string), [
        "roles/bigquery.jobUser",
        "roles/bigquery.user",
        "roles/storage.objectAdmin",
      ])
    }), {})
  }))

  validation {
    condition = alltrue([
      for key, settings in var.worker_pool_settings : (
        (settings.kms_project_id == null && settings.kms_key_ring == null && settings.kms_crypto_key == null)
        || (settings.kms_project_id != null && settings.kms_key_ring != null && settings.kms_crypto_key != null)
      )
    ])
    error_message = "Para usar CMEK no bucket padrão do Cloud Build, informe kms_project_id, kms_key_ring e kms_crypto_key juntos (ou nenhum dos três)."
  }
}
