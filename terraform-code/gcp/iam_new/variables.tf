variable "project_id" {
  description = "Projeto GCP onde todos os recursos de IAM deste módulo serão criados."
  type        = string

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id não pode ser vazio."
  }
}

#
# CUSTOM ROLES
#
variable "custom_roles" {
  description = "Roles customizadas de projeto a criar. A chave do mapa é a referência estável usada em iam_bindings através do valor \"custom:<chave>\"."
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
# GRANTS
#
variable "iam_bindings" {
  description = <<-EOT
    Concede uma role (predefinida "roles/x" ou customizada "custom:<chave>") a uma lista de membros
    (formato completo do GCP, ex.: "group:x@dominio.com", "serviceAccount:x@projeto.iam.gserviceaccount.com",
    "user:x@dominio.com"). Este módulo não cria Service Accounts nem nenhuma outra identidade — quem for
    Service Account deve já existir (tipicamente criada pelo módulo "service_account" ou por um módulo de
    recurso específico) e ser referenciada aqui pelo seu e-mail.
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
