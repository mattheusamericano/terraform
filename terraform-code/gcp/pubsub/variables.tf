variable "pubsub_topic_settings"{
    type = map(object({
        project_id              = string
        sigla                   = string
        labels                  = map(any)
    }))
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