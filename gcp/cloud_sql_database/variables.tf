variable "cloud_sql_database_settings" {
    type = map(object({
        project_id                  = string
        sigla                       = string
        labels                      = map(any)
        instance_name               = string
    }))
}