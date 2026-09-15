variable "ml_ops_settings" {
  description = "Projeto(s) e grupos organizacionais que recebem os perfis ML Ops (ML Engineer, ML Data Scientist, Data Engineer). Ver README."
  type = map(object({
    project_id       = string
    environment_type = string

    ml_engineer_org_group       = optional(string, null)
    ml_data_scientist_org_group = optional(string, null)
    data_engineer_org_group     = optional(string, null)
  }))

  validation {
    condition = alltrue([
      for _, s in var.ml_ops_settings : contains(["nprod", "prod"], s.environment_type)
    ])
    error_message = "environment_type precisa ser \"nprod\" ou \"prod\" em cada entrada de ml_ops_settings."
  }
}

variable "extra_group_role_bindings" {
  description = "Bindings extras de grupo/role, definidos explicitamente por ambiente. Ver README."
  type = map(object({
    role          = string
    members       = list(string)
    authoritative = optional(bool, false)
  }))
  default = {}
}
