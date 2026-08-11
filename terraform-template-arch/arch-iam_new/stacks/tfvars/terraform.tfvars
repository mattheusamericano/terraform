#
# PROJETO
#
project_id = "__project_id__"

#
# SERVICE_ACCOUNT
#
sa_settings = {

  #1 Global
  "sa-global" = {
    display_name = "SA Global by Terraform"
    sigla        = "__sigla__"
  }
  #2 Integration
  "sa-itg" = {
    display_name = "SA Integração by Terraform"
    sigla        = "__sigla__"
  }
  #3 CloudRun
  "sa-clrun" = {
    display_name = "SA Cloudrun by Terraform"
    sigla        = "__sigla__"
  }
  #4 Composer
  "sa-comp" = {
    display_name = "SA Composer by Terraform"
    sigla        = "__sigla__"
  }
  #5 Dataform Runner
  "sa-dt-run" = {
    display_name = "SA Dataform Runner by Terraform"
    sigla        = "__sigla__"
  }
  #6 Core Secret Accessor
  "sa-cr-acc" = {
    display_name = "SA Core Secret Acessor by Terraform"
    sigla        = "__sigla__"
  }
  #7 Log Viewer Service
  "sa-lg-vw" = {
    display_name = "SA Log Viewer Service by Terraform"
    sigla        = "__sigla__"
  }
  #8 Log Writer Service
  "sa-lg-wr" = {
    display_name = "SA Log Writer Service by Terraform"
    sigla        = "__sigla__"
  }
  #9 Log Admin Service
  "sa-lg-adm" = {
    display_name = "SA Log Admin Service by Terraform"
    sigla        = "__sigla__"
  }
}

#
# Grupos para Custom Roles
#
ml_engineer_org_group       = "group:__group_ml_engineer__"
ml_data_scientist_org_group = "group:__group_data_scientist__"
data_engineer_org_group     = "group:__group_data_engineer__"

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
