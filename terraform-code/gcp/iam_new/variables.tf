variable "project_id" {
  description = "Projeto GCP onde todos os recursos de IAM deste módulo serão criados."
  type        = string

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id não pode ser vazio."
  }
}

variable "dataform_service_agent" {
  description = "Concede ao Dataform Service Agent as permissões necessárias para operar. Ver README."
  type = object({
    enabled                         = optional(bool, false)
    execution_service_account_email = optional(string, null)
    kms_project_id                  = optional(string, null)
  })
  default = {}

  validation {
    condition     = !var.dataform_service_agent.enabled || var.dataform_service_agent.execution_service_account_email != null
    error_message = "dataform_service_agent.execution_service_account_email é obrigatório quando dataform_service_agent.enabled = true."
  }
}

variable "ml_ops_profiles" {
  description = "Concede aos grupos organizacionais informados as roles predefinidas do perfil ML Ops correspondente (ML Engineer, ML Data Scientist, Data Engineer). Ver README."
  type = object({
    enabled          = optional(bool, false)
    environment_type = optional(string, null)

    ml_engineer_org_group       = optional(string, null)
    ml_data_scientist_org_group = optional(string, null)
    data_engineer_org_group     = optional(string, null)
  })
  default = {}

  validation {
    condition     = !var.ml_ops_profiles.enabled || contains(["nprod", "prod"], coalesce(var.ml_ops_profiles.environment_type, ""))
    error_message = "ml_ops_profiles.environment_type precisa ser \"nprod\" ou \"prod\" quando ml_ops_profiles.enabled = true."
  }
}

variable "iam_bindings" {
  description = "Concede uma role predefinida do GCP a uma lista de membros. Ver README."
  type = map(object({
    role          = string
    members       = list(string)
    authoritative = optional(bool, false)
  }))
  default = {}
}
