# ============================================================
# Dataplex - Variables
# ============================================================

variable "dataplex_lake_settings" {
  description = "Mapa de configurações dos Lakes Dataplex. Cada chave representa um domínio de dados (ex: 'modelagem', 'inferencia', 'hub-features')."
  type = map(object({
    project_id        = string
    region            = string
    sigla             = string
    lake_description  = optional(string, "Lake gerenciado via Terraform")
    labels            = map(any)

    # Metastore Dataproc (opcional — para catálogo Hive compartilhado)
    metastore_service = optional(string, null) # ex: "projects/P/locations/R/services/S"

    iam_groups = object({
      admin  = string 
      editor = optional(string, null) # omitir ou null = binding não provisionado
      viewer = optional(string, null) # omitir ou null = binding não provisionado
    })
   }))
  }