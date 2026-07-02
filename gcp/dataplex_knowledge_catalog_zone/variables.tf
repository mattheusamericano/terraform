variable "dataplex_zone_settings" {
  description = "Mapa de zones a serem criadas."
  type = map(object({
    lake_key            = string # chave do lake pai — usado para resolver lake_name via lake_names
    project_id          = string
    region              = string
    sigla               = string
    zone_type           = string # RAW ou CURATED
    location_type       = optional(string, "SINGLE_REGION")
    discovery_enabled   = optional(bool, true)
    discovery_schedule  = optional(string, "0 6 * * *")
    csv_delimiter       = optional(string, null)
    labels              = optional(map(string), {})
  }))
}
