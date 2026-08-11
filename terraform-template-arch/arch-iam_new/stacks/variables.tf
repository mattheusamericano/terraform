#
# PROJETO
#
variable "project_id" {
  type = string
}

#
# SERVICE_ACCOUNT
# Mesmo formato de var.sa_settings do módulo service_account (../../tf-modules-for-gcp/service_account) —
# este stack não cria SA por conta própria, apenas repassa para aquele módulo.
#
variable "sa_settings" {
  type = map(object({
    project_id   = string
    display_name = string
  }))
}

#
# Grupos para Custom Roles
#
variable "ml_engineer_org_group" {
  type    = string
  default = null
}
variable "ml_data_scientist_org_group" {
  type    = string
  default = null
}
variable "data_engineer_org_group" {
  type    = string
  default = null
}

#
# Bindings extras de grupo/role, definidos explicitamente por ambiente.
# Substitui o grupo que antes vinha hardcoded no código do módulo (G_GCP_RISCFAB_DTSC@...).
# Formato idêntico ao input `iam_bindings` do módulo iam_new — ver README do módulo.
#
variable "extra_group_role_bindings" {
  type = map(object({
    role          = string
    members       = list(string)
    authoritative = optional(bool, false)
  }))
  default = {}
}
