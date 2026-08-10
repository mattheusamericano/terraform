variable "dataform_repository_settings" {
    type = map(object({
        project_id                  = string
        region                      = string
        sigla                       = string
        service_account_id          = string
        git_url                     = optional(string)
        git_default_branch          = optional(string)
        git_secret_version          = optional(string)
        labels                      = map(any)
    }))
}