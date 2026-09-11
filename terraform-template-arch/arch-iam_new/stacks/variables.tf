#
# PROJETO(S) e PERFIS ML OPS
#
# Agrupado em map(object) em vez de variáveis soltas — mesmo padrão usado nos
# outros módulos deste repositório (ex.: sa_settings no service_account,
# workbench_settings no workbench): a chave do mapa é escolhida livremente por
# quem preenche o tfvars (normalmente a sigla/alias do projeto), não uma chave
# fixa. Isso é diferente do padrão do módulo iam antigo, onde o mapa
# (iam_settings["iam"]) só aceitava uma entrada indexada sempre pela mesma
# string literal e por isso não trazia benefício algum (ver README do
# iam_new) — aqui a chave é de fato livre e permite, se um ambiente precisar,
# declarar mais de um projeto neste mesmo stack.
#
# As listas de roles por perfil (ML Engineer/Data Scientist/Data Engineer) e a
# distinção nprod x prod não são configuráveis aqui — vivem dentro do módulo
# iam_new (ml_ops_profiles.tf). Cada entrada deste mapa só informa QUEM (os 3
# grupos organizacionais) e QUAL o estágio do ambiente (environment_type),
# nunca QUAIS roles — ver main.tf. environment_type é uma condição genérica
# de ambiente (não amarrada a "modelagem"/"inferência" nem a projetos de ML
# especificamente) — cabe em qualquer projeto que use este stack.
variable "ml_ops_settings" {
  description = <<-EOT
    Um objeto por entrada define o projeto e os grupos organizacionais que recebem os perfis
    ML Ops (ML Engineer, ML Data Scientist, Data Engineer) daquele projeto. A chave do mapa é
    livre (sugestão: sigla do projeto/ambiente).

    - project_id: projeto GCP onde os grants serão criados.
    - environment_type: "nprod" (conjunto completo de roles) ou "prod" (reduz cada perfil aos
      equivalentes "viewer"). Repassado direto para module.iam.ml_ops_profiles. Sem default de
      propósito — melhor falhar o plan pedindo o valor do que silenciosamente conceder o
      conjunto de nprod (mais permissivo) num projeto de prod por esquecimento.
    - ml_engineer_org_group / ml_data_scientist_org_group / data_engineer_org_group: e-mail do
      grupo (formato completo, ex. "group:x@dominio.com"). Omitir um deles (deixar null) só
      não concede aquele perfil — não é erro.
  EOT
  type = map(object({
    project_id       = string
    environment_type = string

    ml_engineer_org_group       = optional(string, null)
    ml_data_scientist_org_group = optional(string, null)
    data_engineer_org_group     = optional(string, null)
  }))

  validation {
    condition = alltrue([
      for _, s in var.ml_ops_settings : contains(["nprod", "prod"], s.environment_type)
    ])
    error_message = "environment_type precisa ser \"nprod\" ou \"prod\" em cada entrada de ml_ops_settings."
  }
}

#
# Bindings extras de grupo/role, definidos explicitamente por ambiente.
# Substitui o grupo que antes vinha hardcoded no código do módulo (G_GCP_RISCFAB_DTSC@...).
# Formato idêntico ao input `iam_bindings` do módulo iam — ver README do módulo. Aplicado
# igualmente a toda entrada de ml_ops_settings (não é por projeto).
#
variable "extra_group_role_bindings" {
  type = map(object({
    role          = string
    members       = list(string)
    authoritative = optional(bool, false)
  }))
  default = {}
}
