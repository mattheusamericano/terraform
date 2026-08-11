#
# SERVICE ACCOUNTS
# Este stack não cria SA diretamente — delega para o módulo genérico já usado
# pelos demais módulos de recurso do repositório.
#
module "service_account" {
  source = "../../tf-modules-for-gcp/service_account"

  sa_settings = var.sa_settings
}

#
# IAM
#
module "iam" {
  source     = "../../tf-modules-for-gcp/iam_new"
  project_id = var.project_id

  custom_roles = {
    # Criadas mas não vinculadas a nenhum membro dentro deste stack — igual ao
    # comportamento do módulo antigo. Provavelmente consumidas por outro
    # stack/processo fora daqui; mantido por compatibilidade.
    dataform_service_account_role = {
      role_id     = "dataformServiceAccountBasicRole"
      title       = "Dataform Service Account basic role"
      description = "[Terraform] - Basic permissions for Dataform User Service Account"
      permissions = local.permissions_bigquery_dataform
    }
    machine_learning_viewer = {
      role_id     = "ENG_VIEWER"
      title       = "ENG_VIEWER"
      description = "[Terraform] - Permissions to allow view resources related to Machine Learning practices within GCP"
      permissions = local.permissions_ml_viewer
    }

    machine_learning_engineer = {
      role_id     = "ENG_MLOPS"
      title       = "ENG_MLOPS"
      description = "[Terraform] - Basic permissions to allow Machine Learning Engineer role to use resources related to Machine Learning practices within GCP"
      permissions = local.permissions_ml_engineer
    }
    data_engineer = {
      role_id     = "ENG_DADOS"
      title       = "ENG_DADOS"
      description = "[Terraform] - Basic permissions to allow Data Engineer role to use resources related to Machine Learning practices within GCP"
      permissions = local.permissions_data_engineer
    }
    machine_learning_data_scientist = {
      role_id     = "CIENTISTA_DADOS"
      title       = "CIENTISTA_DADOS"
      description = "[Terraform] - Basic permissions to allow Machine Learning Data Scientist role to use resources related to Machine Learning practices within GCP"
      permissions = local.permissions_ml_data_scientist
    }
  }

  # Une os grants das Service Accounts internas, os grants dos grupos de ML/Dados
  # e quaisquer grants extras definidos explicitamente por ambiente (ex.: o grupo
  # que antes vinha hardcoded no módulo antigo — ver variable "extra_group_role_bindings").
  iam_bindings = merge(
    local.sa_role_iam_bindings,
    local.group_role_bindings,
    var.extra_group_role_bindings,
  )
}
