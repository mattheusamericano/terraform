variable "feature_store_settings" {
  description = "Feature Store Settings"
  type = map(object({
    project_id = string
    region = string
    sigla = string
    kms_project_id = string
    key_ring = string
    key_crypto = string
    labels = map(any)
  }))
}
