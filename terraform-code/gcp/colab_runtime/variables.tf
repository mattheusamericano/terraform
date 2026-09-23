variable "colab_runtime_template_settings" {
  type = map(object({
    project_id             = string
    region                 = string
    sigla                  = string
    machine_type           = string
    accelerator_type       = optional(string)
    accelerator_count      = optional(string)
    disk_type              = string
    disk_size_gb           = number
    network_project_id     = string
    name_vpc_shared        = string
    name_subnet_vpc_shared = string
    labels                 = map(any)
    kms_project_id         = optional(string)
    kms_key_ring           = optional(string)
    kms_crypto_key         = optional(string)

  }))

  validation {
    condition = alltrue([
      for key, value in var.colab_runtime_template_settings : (
        (value.kms_project_id == null && value.kms_key_ring == null && value.kms_crypto_key == null)
        || (value.kms_project_id != null && value.kms_key_ring != null && value.kms_crypto_key != null)
      )
    ])
    error_message = "Para usar CMEK, informe kms_project_id, kms_key_ring e kms_crypto_key juntos (ou nenhum dos três). A location da chave usa o mesmo valor de region."
  }
}