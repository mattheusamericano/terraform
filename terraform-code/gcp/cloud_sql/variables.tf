variable "cloud_sql_instance_settings" {
    type = map(object({
        project_id                  = string
        region                      = string
        sigla                       = string
        tier                        = string
        database_version            = string
        disk_type                   = string
        disk_size                   = number
        disk_autoresize_limit       = optional(number)
        network_project_id          = string
        name_vpc_shared             = string
        key_ring                    = string
        key_crypto                  = string
        kms_project_id              = string
        labels                      = map(any)
        group_users                 = string
    }))
}