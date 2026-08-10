variable "cos_bucket_settings" {
  description = "Mapa de configuracao dos buckets do IBM Cloud Object Storage (COS). Cada chave representa um bucket logico dentro de uma instancia COS ja existente."

  type = map(object({
    sigla = string

    instance_crn  = string # CRN da instancia COS (output.instance_crns do modulo cos_instance)
    instance_guid = string # GUID da instancia COS (output.instance_guids do modulo cos_instance) - usado para IAM em nivel de bucket

    # Preencher exatamente um par (location_type, location):
    # location_type = "region"        -> location em region_location (ex: "us-south", "br-sao")
    # location_type = "cross_region"  -> location em cross_region_location (ex: "us", "eu", "ap")
    # location_type = "single_site"   -> location em single_site_location (ex: "sao01")
    location_type = string
    location      = string

    storage_class = optional(string, "standard") # standard | vault | cold | smart | onerate_active
    endpoint_type = optional(string, "public")   # public | private | direct

    force_delete = optional(bool, true)
    hard_quota   = optional(number, null)       # limite de armazenamento em bytes
    allowed_ip   = optional(list(string), null) # CIDRs com acesso permitido ao bucket
    object_lock  = optional(bool, false)

    object_versioning_enabled = optional(bool, false)

    # CMEK. CRN da chave Key Protect/HPCS. A instancia dona da chave precisa ja
    # ter sido autorizada a usa-la via kms_instance_guid no modulo cos_instance.
    kms_key_crn = optional(string, null)

    retention_rule = optional(object({
      default   = number # dias de retencao aplicados por padrao a novos objetos
      maximum   = number
      minimum   = number
      permanent = optional(bool, false)
    }), null)

    activity_tracking = optional(object({
      read_data_events     = optional(bool, false)
      write_data_events    = optional(bool, false)
      management_events    = optional(bool, false)
      activity_tracker_crn = optional(string, null)
    }), null)

    metrics_monitoring = optional(object({
      usage_metrics_enabled   = optional(bool, false)
      request_metrics_enabled = optional(bool, false)
      metrics_monitoring_crn  = optional(string, null)
    }), null)

    # IAM restrito a ESTE bucket (nao afeta os demais buckets da instancia)
    iam_bindings = optional(object({
      managers = optional(list(string), []) # IDs de access group com roles/Manager no bucket
      writers  = optional(list(string), []) # IDs de access group com roles/Writer no bucket
      readers  = optional(list(string), []) # IDs de access group com roles/Reader no bucket
    }), {})
  }))
}
