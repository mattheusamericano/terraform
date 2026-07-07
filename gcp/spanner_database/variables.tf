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

    iam_bindings = optional(object({
      database_admins  = optional(list(string), []) # roles/spanner.databaseAdmin
      database_users   = optional(list(string), []) # roles/spanner.databaseUser
      database_readers = optional(list(string), []) # roles/spanner.databaseReader
    }), {})
  }))
}
