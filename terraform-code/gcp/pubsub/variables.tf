variable "pubsub_topic_settings"{
    type = map(object({
        project_id              = string
        sigla                   = string
        labels                  = map(any)
        kms_project_id          = optional(string)
        region                  = optional(string)
        kms_key_ring            = optional(string)
        kms_crypto_key          = optional(string)
    }))

    validation {
      condition = alltrue([
        for key, value in var.pubsub_topic_settings : (
          (value.kms_project_id == null && value.region == null && value.kms_key_ring == null && value.kms_crypto_key == null)
          || (value.kms_project_id != null && value.region != null && value.kms_key_ring != null && value.kms_crypto_key != null)
        )
      ])
      error_message = "Para usar CMEK, informe kms_project_id, region, kms_key_ring e kms_crypto_key juntos (ou nenhum dos quatro)."
    }
}
variable "pubsub_settings"{
    type = map(object({
        project_id                      = string
        topic_name                      = string
        ack_deadline_seconds            = number
        message_retention_duration      = string
        retain_acked_messages           = optional(bool, true)
        sigla                           = string
        labels                          = map(any)
    }))
}