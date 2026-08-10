variable "dataplex_asset_settings" {
  description = "Mapa de assets a serem criados. Chave = lake_key__asset_key."
  type = map(object({
    lake_key            = string # chave do lake pai — resolve lake_name via lake_names
    zone_key            = string # chave completa lake_key__zone_key — resolve zone_name via zone_names
    project_id          = string
    region              = string
    sigla               = string
    resource_type       = string # BIGQUERY_DATASET ou STORAGE_BUCKET
    resource_name       = string # ex: projects/P/datasets/D ou projects/P/buckets/B
    asset_description   = optional(string, "Asset gerenciado via Terraform")
    discovery_enabled   = optional(bool, true)
    discovery_schedule  = optional(string, null)
    labels              = optional(map(string), {})
  }))
}
