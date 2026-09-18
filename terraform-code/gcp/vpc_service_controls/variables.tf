variable "access_policy_id" {
  description = "ID numérico da Access Policy do GCP onde o Service Perimeter alvo das regras vive (ex.: \"412713748361\")."
  type        = string
  default     = "412713748361"
}

variable "perimeter_name" {
  description = "Nome do Service Perimeter já existente ao qual as regras de ingress/egress serão anexadas (ex.: \"perimetroprojetoscaixa\"). Este módulo NÃO cria nem gerencia a definição do perímetro em si (recursos, restricted services, access levels) — só anexa regras de ingress/egress a um perímetro que já existe."
  type        = string
  default     = "perimetroprojetoscaixa"
}

variable "ingress_policies" {
  description = "Mapa de regras de ingress (tráfego ENTRANDO no perímetro) a criar. A chave do mapa vira o title da regra quando title não é informado. Ver README para a semântica completa de identity_type/sources/operations."
  type = map(object({
    title = optional(string)

    ingress_from = object({
      identity_type = optional(string, "ANY_IDENTITY")
      identities    = optional(list(string), [])

      sources = optional(list(object({
        access_level = optional(string)
        resource     = optional(string)
      })), [])
    })

    ingress_to = object({
      resources = list(string)
      roles     = optional(list(string), [])

      operations = list(object({
        service_name = string

        method_selectors = optional(list(object({
          method     = optional(string)
          permission = optional(string)
        })), [])
      }))
    })
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for key, rule in var.ingress_policies : [
        for source in rule.ingress_from.sources : (
          (source.access_level != null && source.resource == null)
          || (source.access_level == null && source.resource != null)
        )
      ]
    ]))
    error_message = "Em ingress_policies.*.ingress_from.sources, cada source precisa ter access_level OU resource preenchido (nunca os dois, nunca nenhum)."
  }
}

variable "egress_policies" {
  description = "Mapa de regras de egress (tráfego SAINDO do perímetro) a criar. A chave do mapa vira o title da regra quando title não é informado. Ver README para a semântica completa de identity_type/sources/operations."
  type = map(object({
    title = optional(string)

    egress_from = object({
      identity_type      = optional(string, "ANY_IDENTITY")
      identities         = optional(list(string), [])
      source_restriction = optional(string)

      sources = optional(list(object({
        access_level = optional(string)
        resource     = optional(string)
      })), [])
    })

    egress_to = object({
      resources          = list(string)
      external_resources = optional(list(string), [])
      roles              = optional(list(string), [])

      operations = list(object({
        service_name = string

        method_selectors = optional(list(object({
          method     = optional(string)
          permission = optional(string)
        })), [])
      }))
    })
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for key, rule in var.egress_policies : [
        for source in rule.egress_from.sources : (
          (source.access_level != null && source.resource == null)
          || (source.access_level == null && source.resource != null)
        )
      ]
    ]))
    error_message = "Em egress_policies.*.egress_from.sources, cada source precisa ter access_level OU resource preenchido (nunca os dois, nunca nenhum)."
  }
}
