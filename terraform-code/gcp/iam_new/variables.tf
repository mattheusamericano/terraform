variable "project_id" {
  description = "Projeto GCP onde todos os recursos de IAM deste módulo serão criados."
  type        = string

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id não pode ser vazio."
  }
}

#
# SERVICE ACCOUNTS
#
variable "sa_settings" {
  description = "Service Accounts a serem criadas. A chave do mapa é a referência estável usada em sa_role_bindings (sa_key). project_id é opcional e, se omitido, usa var.project_id."
  type = map(object({
    display_name = string
    sigla        = string
    project_id   = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.sa_settings : can(regex("^[a-z][a-z0-9-]{4,28}$", "${k}-${v.sigla}"))
    ])
    error_message = "Para cada entrada de sa_settings, \"<chave>-<sigla>\" deve começar com letra minúscula, conter apenas [a-z0-9-] e ter entre 6 e 30 caracteres (limite de account_id do GCP, já reservando espaço para o sufixo de workspace)."
  }
}

#
# CUSTOM ROLES
#
variable "custom_roles" {
  description = "Roles customizadas de projeto a criar. A chave do mapa é a referência estável usada em sa_role_bindings/iam_bindings através do valor \"custom:<chave>\"."
  type = map(object({
    role_id     = string
    title       = string
    description = optional(string, "")
    permissions = list(string)
    stage       = optional(string, "GA")
  }))
  default = {}
}

#
# GRANTS PARA SERVICE ACCOUNTS CRIADAS POR ESTE MÓDULO
#
variable "sa_role_bindings" {
  description = "Concede roles (predefinidas \"roles/x\" ou customizadas \"custom:<chave-de-custom_roles>\") às Service Accounts criadas em sa_settings. Sempre aditivo (google_project_iam_member) — nunca remove outros membros da role. A chave do mapa é apenas um identificador legível."
  type = map(object({
    sa_key = string
    role   = string
  }))
  default = {}
}

#
# GRANTS PARA GRUPOS/USUÁRIOS/SAS EXTERNAS
#
variable "iam_bindings" {
  description = <<-EOT
    Concede uma role (predefinida "roles/x" ou customizada "custom:<chave>") a uma lista de membros
    (formato completo do GCP, ex.: "group:x@dominio.com", "serviceAccount:x@projeto.iam.gserviceaccount.com").
    Por padrão usa google_project_iam_member (aditivo e seguro: não afeta outros membros da mesma role).
    Definir authoritative = true faz esse binding usar google_project_iam_binding, que é AUTORITATIVO e
    substitui TODOS os membros da role a cada apply — use apenas quando isso for intencional, pois qualquer
    membro adicionado fora do Terraform (manualmente ou por outro processo) será removido no próximo apply.
  EOT
  type = map(object({
    role          = string
    members       = list(string)
    authoritative = optional(bool, false)
  }))
  default = {}
}
