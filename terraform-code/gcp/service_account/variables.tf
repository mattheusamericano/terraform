variable "sa_settings" {
  description = "Mapa de Service Accounts a serem criadas, uma entrada por conta. A chave do mapa é usada como parte do account_id."
  type = map(object({
    project_id   = string
    sigla        = string
    display_name = optional(string)
    description  = optional(string, "Service Account gerenciada via Terraform")
    disabled     = optional(bool, false)
  }))
}
