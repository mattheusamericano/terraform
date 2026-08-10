variable "bucket_settings" {
  type = map(object({
    project_id                  = string
    sigla                       = string
    region                      = string
    storage_class               = string
    kms_key_name                = string
    kms_key_crypto              = string
    kms_project_id              = string
    labels                      = map(string)
  }))
}

