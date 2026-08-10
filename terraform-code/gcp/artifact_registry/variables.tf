variable "artifact_registry_settings"{
  type = map(object({
    project_id                          = string
    region                              = string
    artifact_format                     = string  
    artifact_mode                       = string
    cleanup_policy_dry_run              = optional(bool, true)
    sigla                               = string
    labels                              = map(any)
    
    }))
}
