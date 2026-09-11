#
# PROJETO(S) e PERFIS ML OPS
#
# A chave do mapa é livre — aqui usamos a sigla do projeto/ambiente. Um único
# projeto é o caso normal; só tem mais de uma entrada se este stack precisar
# aplicar em mais de um projeto de uma vez.
#
ml_ops_settings = {
  "__sigla__" = {
    project_id       = "__project_id__"
    environment_type = "__environment_type__" # "nprod" ou "prod" — ver módulo iam (ml_ops_profiles.tf)

    ml_engineer_org_group       = "group:__group_ml_engineer__"
    ml_data_scientist_org_group = "group:__group_data_scientist__"
    data_engineer_org_group     = "group:__group_data_engineer__"
  }
}

#
# Bindings extras de grupo/role específicos deste ambiente. Antes, um grupo
# fixo (G_GCP_RISCFAB_DTSC@corp.caixa.gov.br) vinha hardcoded no código do
# módulo, recebendo roles/aiplatform.admin e roles/iam.dataScientist para
# TODO ambiente que usasse o módulo. Agora isso é opt-in e explícito por
# ambiente — descomente e ajuste se este ambiente realmente precisar conceder
# esses acessos:
#
# extra_group_role_bindings = {
#   riscfab_datascientist = {
#     role    = "roles/iam.dataScientist"
#     members = ["group:__group_ml_engineer__"]
#   }
#   riscfab_aiplatform_admin = {
#     role    = "roles/aiplatform.admin"
#     members = ["group:__group_ml_engineer__"]
#   }
# }
