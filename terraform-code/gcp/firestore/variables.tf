# ============================================================
# Variables - Firestore Database Module
# ============================================================

variable "firestore_settings" {
  type = map(object({
    project_id          = string
    region              = string
    sigla               = string
    type                = optional(string, "FIRESTORE_NATIVE")
    kms_project_id      = optional(string, null)
    kms_keyring         = optional(string, null)
    kms_crypto          = optional(string, null)
    group_writer        = string
    group_reader        = optional(string)
    labels              = map(any)
  }))

}