#
# IAM
# Este stack não cria nenhuma Service Account — só concede roles a
# identidades que já existem (grupos organizacionais, e quaisquer SAs
# externas via var.extra_group_role_bindings). Quem precisar de uma SA usa o
# módulo service_account (../../../terraform-code/gcp/service_account)
# separadamente.
#
# As roles de cada perfil (ML Engineer/Data Scientist/Data Engineer, só
# roles predefinidas do GCP — não há mais custom role para nenhum perfil) e a
# distinção nprod x prod vivem dentro do módulo iam (ml_ops_profiles.tf), não
# aqui — este stack só repassa QUEM (grupos, via var.ml_ops_settings) e QUAL
# o estágio do ambiente (environment_type, idem). Isso é deliberado: quem
# edita este stack não deve poder mudar quais roles um perfil recebe, só
# quem tem acesso — mudar o conjunto de roles é uma decisão de segurança que
# exige editar o módulo.
#
# for_each sobre var.ml_ops_settings: normalmente uma única entrada (um
# projeto por ambiente), mas o mapa permite mais de um projeto no mesmo stack
# se algum ambiente precisar.
#
module "iam" {
  source   = "../../../terraform-code/gcp/iam_new"
  for_each = var.ml_ops_settings

  project_id = each.value.project_id

  ml_ops_profiles = {
    enabled                     = true
    environment_type            = each.value.environment_type
    ml_engineer_org_group       = each.value.ml_engineer_org_group
    ml_data_scientist_org_group = each.value.ml_data_scientist_org_group
    data_engineer_org_group     = each.value.data_engineer_org_group
  }

  # Grants extras definidos explicitamente por ambiente (ex.: o grupo que
  # antes vinha hardcoded no módulo antigo — ver variable
  # "extra_group_role_bindings"). Aplicado igualmente a toda entrada.
  iam_bindings = var.extra_group_role_bindings
}
