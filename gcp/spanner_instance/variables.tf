variable "spanner_instance_settings" {
  description = "Mapa de configuração das instâncias Cloud Spanner. Cada chave representa uma instância lógica."
  type = map(object({
    sigla            = string
    project_id       = string
    config           = string # ex: regional-southamerica-east1 ou nam-eur-asia1 para multi-região
    display_name     = optional(string)
    processing_units = optional(number, 1000) # múltiplo de 100. 1000 PU = 1 node
    edition          = optional(string, "STANDARD") # STANDARD | ENTERPRISE | ENTERPRISE_PLUS
    labels           = optional(map(string), {})

    iam_bindings = optional(object({
      admins          = optional(list(string), []) # roles/spanner.admin
      database_admins = optional(list(string), []) # roles/spanner.databaseAdmin
      viewers         = optional(list(string), []) # roles/spanner.viewer
    }), {})
  }))
}
