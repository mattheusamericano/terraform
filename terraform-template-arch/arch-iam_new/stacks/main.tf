#
# IAM
#
module "iam" {
  source     = "../../tf-modules-for-gcp/iam_new"
  project_id = var.project_id

  sa_settings = var.sa_settings

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

  sa_role_bindings = merge(
    { for k, role in local.permissions_sa_global : "global-${k}" => { sa_key = "sa-global", role = role } },
    { for k, role in local.permissions_sa_composer : "composer-${k}" => { sa_key = "sa-comp", role = role } },
    local.permissions_sa_pontuais,
  )

  # Une os grants dos grupos de ML/Dados com quaisquer grants extras definidos
  # explicitamente por ambiente (ex.: o grupo que antes vinha hardcoded no
  # módulo antigo — ver variable "extra_group_role_bindings").
  iam_bindings = merge(local.group_role_bindings, var.extra_group_role_bindings)
}
