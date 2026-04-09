# ============================================================
# Variables - Firestore Database Module
# ============================================================

variable "firestore_settings" {
  type = map(object({
    project_id  = string
    region      = string
    sigla       = string

    # FIRESTORE_NATIVE ou DATASTORE_MODE
    type = optional(string, "FIRESTORE_NATIVE")

    # KMS (null = sem criptografia gerenciada)
    kms_project_id   = optional(string, null)
    kms_keyring_name = optional(string, null)
    kms_key_name     = optional(string, null)

    # IAM
    group_writer  = string
    groups_reader = optional(list(string), [])

    labels = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.firestore_settings :
      contains(["FIRESTORE_NATIVE", "DATASTORE_MODE"], v.type)
    ])
    error_message = "type deve ser FIRESTORE_NATIVE ou DATASTORE_MODE."
  }
}
