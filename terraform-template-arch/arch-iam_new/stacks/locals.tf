locals {
  common_labels = {
    "Ambiente"      = "__environment__"
    "EquipeInfra"   = "CESTI35"
    "EquipeSolucao" = "__sigla__"
    "Solucao"       = "__sigla__"
    "Provimento"    = "Terraform"
    "Workload"      = "__sigla__"
  }

  #
  # Roles concedidas às Service Accounts internas (sempre aditivo).
  # As SAs em si são criadas pelo módulo service_account (module.service_account),
  # não por este stack nem pelo módulo iam_new — ver main.tf.
  #
  permissions_sa_global = {
    permissao_service_agent_composer = "roles/composer.ServiceAgentV2Ext"
    permissao_bigquery_admin         = "roles/bigquery.admin"
    permissao_storage_admin          = "roles/storage.admin"
    permissao_pub_sub_subscriber     = "roles/pubsub.subscriber"
    permissao_pub_sub_publisher      = "roles/pubsub.publisher"
    permissao_dataproc_worker        = "roles/dataproc.worker"
    permissao_composer_worker        = "roles/composer.worker"
    permissao_dataflow_worker        = "roles/dataflow.worker"
    permissoes_sa_global_bigdata     = "roles/bigquery.dataViewer"
  }

  permissions_sa_composer = {
    composer_log_entry             = "roles/logging.logWriter"
    composer_service_account_agent = "roles/composer.ServiceAgentV2Ext"
    composer_bigquery              = "roles/bigquery.admin"
    composer_storage               = "roles/storage.admin"
  }

  # Roles pontuais concedidas às demais Service Accounts internas (substituem
  # os resources fixos que existiam em roles.tf no módulo antigo).
  sa_role_iam_bindings = merge(
    { for k, role in local.permissions_sa_global : "global-${k}" => {
      role    = role
      members = ["serviceAccount:${module.service_account.service_account_emails["sa-global"]}"]
      }
    },
    { for k, role in local.permissions_sa_composer : "composer-${k}" => {
      role    = role
      members = ["serviceAccount:${module.service_account.service_account_emails["sa-comp"]}"]
      }
    },
    {
      core_secret_accessor = {
        role    = "roles/secretmanager.secretAccessor"
        members = ["serviceAccount:${module.service_account.service_account_emails["sa-cr-acc"]}"]
      }
      log_viewer_accessor = {
        role    = "roles/logging.viewer"
        members = ["serviceAccount:${module.service_account.service_account_emails["sa-lg-vw"]}"]
      }
      log_writer_accessor = {
        role    = "roles/logging.logWriter"
        members = ["serviceAccount:${module.service_account.service_account_emails["sa-lg-wr"]}"]
      }
      log_writer_bq_editor = {
        role    = "roles/bigquery.dataEditor"
        members = ["serviceAccount:${module.service_account.service_account_emails["sa-lg-wr"]}"]
      }
      log_admin_accessor = {
        role    = "roles/logging.admin"
        members = ["serviceAccount:${module.service_account.service_account_emails["sa-lg-adm"]}"]
      }
    },
  )

  #
  # Grants para os grupos organizacionais (ML Engineer / Data Scientist / Data Engineer).
  # Equivalente ao que estava espalhado em roles.tf + iam_binging.tf no módulo antigo,
  # agora centralizado e visível em um único lugar por ambiente.
  #
  # As custom roles (ENG_MLOPS, CIENTISTA_DADOS, ENG_DADOS) usavam google_project_iam_binding
  # (autoritativo) no módulo antigo. Aqui usamos aditivo por padrão (mais seguro — ver README
  # do módulo iam_new); se o comportamento autoritativo for realmente necessário, marque
  # authoritative = true na entrada correspondente.
  #
  group_role_bindings = merge(
    var.ml_engineer_org_group == null ? {} : {
      ml_engineer_custom_role                 = { role = "custom:machine_learning_engineer", members = [var.ml_engineer_org_group] }
      ml_engineer_iap_https_resource_accessor = { role = "roles/iap.httpsResourceAccessor", members = [var.ml_engineer_org_group] }
      ml_engineer_cloud_run_developer         = { role = "roles/run.developer", members = [var.ml_engineer_org_group] }
      ml_engineer_aiplatform_viewer           = { role = "roles/aiplatform.viewer", members = [var.ml_engineer_org_group] }
      ml_engineer_iam_role_viewer             = { role = "roles/iam.roleViewer", members = [var.ml_engineer_org_group] }
      ml_engineer_cloudbuild_connection_admin = { role = "roles/cloudbuild.connectionAdmin", members = [var.ml_engineer_org_group] }
    },
    var.ml_data_scientist_org_group == null ? {} : {
      ml_data_scientist_custom_role     = { role = "custom:machine_learning_data_scientist", members = [var.ml_data_scientist_org_group] }
      ml_data_scientist_aiplatform_user = { role = "roles/aiplatform.user", members = [var.ml_data_scientist_org_group] }
      ml_data_scientist_iam_role_viewer = { role = "roles/iam.roleViewer", members = [var.ml_data_scientist_org_group] }
      ml_data_scientist_dataform_editor = { role = "roles/dataform.editor", members = [var.ml_data_scientist_org_group] }
      ml_data_scientist_storage_admin   = { role = "roles/storage.admin", members = [var.ml_data_scientist_org_group] }
      ml_data_scientist_iam_data_role   = { role = "roles/iam.dataScientist", members = [var.ml_data_scientist_org_group] }
    },
    var.data_engineer_org_group == null ? {} : {
      data_engineer_custom_role       = { role = "custom:data_engineer", members = [var.data_engineer_org_group] }
      data_engineer_aiplatform_viewer = { role = "roles/aiplatform.viewer", members = [var.data_engineer_org_group] }
      data_engineer_iam_role_viewer   = { role = "roles/iam.roleViewer", members = [var.data_engineer_org_group] }
      data_engineer_bq_data_editor    = { role = "roles/bigquery.dataEditor", members = [var.data_engineer_org_group] }
      data_engineer_dataform_editor   = { role = "roles/dataform.editor", members = [var.data_engineer_org_group] }
      data_engineer_composer_admin    = { role = "roles/composer.admin", members = [var.data_engineer_org_group] }
      data_engineer_dataproc_worker   = { role = "roles/dataproc.worker", members = [var.data_engineer_org_group] }
      data_engineer_storage_admin     = { role = "roles/storage.admin", members = [var.data_engineer_org_group] }
      data_engineer_logging_viewer    = { role = "roles/logging.viewer", members = [var.data_engineer_org_group] }
      data_engineer_ml_engineer_role  = { role = "roles/iam.mlEngineer", members = [var.data_engineer_org_group] }
    },
    {
      # roles/notebooks.runner era concedido, via binding autoritativo, para os grupos de
      # Data Scientist e Data Engineer juntos. Reproduzido aqui como um único grant aditivo.
      notebooks_runner = {
        role    = "roles/notebooks.runner"
        members = compact([var.ml_data_scientist_org_group, var.data_engineer_org_group])
      }
    }
  )
}
