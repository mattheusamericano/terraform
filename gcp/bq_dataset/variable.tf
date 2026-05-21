variable "bq_dataset_settings" {
  type = map(object({
    project_id    = string
    sigla         = string
    region        = string
    group_writer  = string
    sa_name       = string

    labels      = map(string)
    description = optional(string, "Dataset created by Terraform")

    default_table_expiration_ms     = optional(number, null)
    default_partition_expiration_ms = optional(number, null)

    # KMS
    kms_project_id = optional(string, null)
    key_ring       = optional(string, null)
    key_crypto     = optional(string, null)
    kms_key        = optional(string, null)

  }))
}
