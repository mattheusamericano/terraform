variable "wipool_settings" {
    type = map(object({
        project_id              = string
        wipool_display_name     = string
        wipool_provider_id      = string
        attribute_condition     = string
        wipool_issuer_uri       = string
        repository_owner        = string
        wipool_sa_account_id    = string
        attribute_mapping       = optional(map(string))
    }))

}
