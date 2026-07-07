variable "spanner_database_settings" {
  description = "Mapa de configuração dos databases Spanner. Cada chave representa um database lógico dentro de uma instância."
  type = map(object({
    sigla         = string
    project_id    = string
    instance_name = string # nome real da instância (ex: output.instance_names["hub_decision_broker"])

    database_dialect         = optional(string, "GOOGLE_STANDARD_SQL") # ou POSTGRESQL
    ddl                      = optional(list(string), []) # DDL inicial — placeholder, ver nota no example.tfvars
    deletion_protection      = optional(bool, true)
    version_retention_period = optional(string, "1h")

    # CMEK. Preencher no máximo um dos dois:
    # - kms_key_name  -> instância regional (região única)
    # - kms_key_names -> instância multi-região/custom (uma chave por região)
    # Imutável após a criação do database (Spanner não permite trocar depois).
    encryption = optional(object({
      kms_key_name  = optional(string)
      kms_key_names = optional(list(string), [])
      grant_kms_iam = optional(bool, true) # concede cryptoKeyEncrypterDecrypter ao service agent do Spanner
    }))

    iam_bindings = optional(object({
      database_admins  = optional(list(string), []) # roles/spanner.databaseAdmin
      database_users   = optional(list(string), []) # roles/spanner.databaseUser
      database_readers = optional(list(string), []) # roles/spanner.databaseReader
    }), {})
  }))
}
