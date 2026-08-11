#
# PROJETO
#
project_id = "__project_id__"

#
# SERVICE_ACCOUNT
# Repassado como está para o módulo service_account (../../tf-modules-for-gcp/service_account),
# que é quem efetivamente cria as SAs.
#
sa_settings = {

  #1 Global
  "sa-global" = {
    project_id   = "__project_id__"
    display_name = "SA Global by Terraform"
  }
  #2 Integration
  "sa-itg" = {
    project_id   = "__project_id__"
    display_name = "SA Integração by Terraform"
  }
  #3 CloudRun
  "sa-clrun" = {
    project_id   = "__project_id__"
    display_name = "SA Cloudrun by Terraform"
  }
  #4 Composer
  "sa-comp" = {
    project_id   = "__project_id__"
    display_name = "SA Composer by Terraform"
  }
  #5 Dataform Runner
  "sa-dt-run" = {
    project_id   = "__project_id__"
    display_name = "SA Dataform Runner by Terraform"
  }
  #6 Core Secret Accessor
  "sa-cr-acc" = {
    project_id   = "__project_id__"
    display_name = "SA Core Secret Acessor by Terraform"
  }
  #7 Log Viewer Service
  "sa-lg-vw" = {
    project_id   = "__project_id__"
    display_name = "SA Log Viewer Service by Terraform"
  }
  #8 Log Writer Service
  "sa-lg-wr" = {
    project_id   = "__project_id__"
    display_name = "SA Log Writer Service by Terraform"
  }
  #9 Log Admin Service
  "sa-lg-adm" = {
    project_id   = "__project_id__"
    display_name = "SA Log Admin Service by Terraform"
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
