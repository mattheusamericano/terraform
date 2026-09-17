variable "artifact_registry_settings"{
  type = map(object({
    project_id                          = string
    region                              = string
    artifact_format                     = string
    artifact_mode                       = string
    cleanup_policy_dry_run              = optional(bool, true)
    sigla                               = string
    labels                              = map(any)
    description                         = optional(string)
    kms_project_id                      = optional(string)
    kms_key_ring                        = optional(string)
    kms_crypto_key                      = optional(string)

    }))

  validation {
    condition = alltrue([
      for key, value in var.artifact_registry_settings : (
        (value.kms_project_id == null && value.kms_key_ring == null && value.kms_crypto_key == null)
        || (value.kms_project_id != null && value.kms_key_ring != null && value.kms_crypto_key != null)
      )
    ])
    error_message = "Para usar CMEK, informe kms_project_id, kms_key_ring e kms_crypto_key juntos (ou nenhum dos três). A location da chave usa o mesmo valor de region."
  }
}
