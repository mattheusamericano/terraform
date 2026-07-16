variable "agent_builder_endpoint_settings" {
  description = "Mapa de Endpoints do Vertex AI a serem criados."

  type = map(object({
    project_id                 = string
    region                     = string
    sigla                      = string
    endpoint_name              = string
    display_name               = string
    description                = optional(string, null)
    dedicated_endpoint_enabled = optional(bool, false)
    labels                     = optional(map(string), {})
  }))
}