# ============================================================
# Analytics Hub - Variables
# ============================================================

variable "analytics_hub_settings" {
  description = "Mapa de configurações dos Data Exchanges do Analytics Hub."
  type = map(object({

    project_id   = string
    region       = string
    sigla        = string
    display_name = string
    description  = optional(string, "Exchange gerenciado via Terraform")

    # true  = Exchange Privado (DCR) — padrão Caixa, acesso controlado por IAM
    # false = Exchange Público/Aberto — qualquer usuário da org pode descobrir e assinar
    
    is_data_clean_room = optional(bool, false)
    
    iam_groups = object({
      admin       = string
      publisher   = optional(string)
      subscriber  = optional(string)
    })
  }))
}
