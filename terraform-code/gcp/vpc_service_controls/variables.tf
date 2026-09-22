variable "ingress_policies" {
  description = "Mapa de regras de ingress (tráfego ENTRANDO no perímetro) a criar. A chave do mapa vira o title da regra quando title não é informado. access_policy_id/perimeter_name identificam o perímetro alvo de CADA regra (com default, mas sempre presentes no objeto). Ver README para a semântica completa de identity_type/sources/operations."
  type = map(object({
    title            = optional(string)
    access_policy_id = optional(string, "412713748361")
    perimeter_name   = optional(string, "perimetroprojetoscaixa")

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
  description = "Mapa de regras de egress (tráfego SAINDO do perímetro) a criar. A chave do mapa vira o title da regra quando title não é informado. access_policy_id/perimeter_name identificam o perímetro alvo de CADA regra (com default, mas sempre presentes no objeto). Ver README para a semântica completa de identity_type/sources/operations."
  type = map(object({
    title            = optional(string)
    access_policy_id = optional(string, "412713748361")
    perimeter_name   = optional(string, "perimetroprojetoscaixa")

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
