variable "cos_instance_settings" {
  description = "Mapa de configuracao das instancias IBM Cloud Object Storage (COS). Cada chave representa uma instancia logica."

  type = map(object({
    sigla             = string
    resource_group_id = string

    plan     = optional(string, "standard") # lite | standard | cos-satellite
    location = optional(string, "global")   # instancias COS sao sempre "global"
    tags     = optional(list(string), [])

    # KMS (opcional) - autoriza esta instancia COS a usar chaves de uma
    # instancia Key Protect ou Hyper Protect Crypto Services (HPCS) existente
    kms_service_name  = optional(string, "kms") # "kms" (Key Protect) ou "hs-crypto" (HPCS)
    kms_instance_guid = optional(string, null)

    # IAM em nivel de instancia: acesso concedido em TODOS os buckets dela.
    # Para acesso restrito a um bucket especifico, use iam_bindings no modulo cos_bucket.
    iam_bindings = optional(object({
      managers = optional(list(string), []) # IDs de access group com roles/Manager na instancia
      writers  = optional(list(string), []) # IDs de access group com roles/Writer na instancia
      readers  = optional(list(string), []) # IDs de access group com roles/Reader na instancia
    }), {})
  }))
}
