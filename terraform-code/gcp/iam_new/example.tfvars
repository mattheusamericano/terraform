project_id = "prj-meuproduto-mdl-prd"

custom_roles = {
  data_engineer = {
    role_id     = "ENG_DADOS"
    title       = "ENG_DADOS"
    description = "Perfil de engenharia de dados"
    permissions = [
      "bigquery.tables.get",
      "bigquery.tables.list",
    ]
  }
}

iam_bindings = {
  # aditivo (padrão) — não remove outros membros já existentes na role
  global_bq_admin = {
    role    = "roles/bigquery.admin"
    members = ["serviceAccount:sa-global@prj-meuproduto-mdl-prd.iam.gserviceaccount.com"]
  }

  data_engineer_custom_role = {
    role    = "custom:data_engineer"
    members = ["group:g-data-engineers@empresa.com"]
  }

  # autoritativo (opt-in explícito) — substitui TODOS os membros da role a cada apply
  notebooks_runner = {
    role          = "roles/notebooks.runner"
    members       = ["serviceAccount:sa-comp@prj-meuproduto-mdl-prd.iam.gserviceaccount.com"]
    authoritative = true
  }
}

# Permissões do Dataform Service Agent (identidade gerenciada pelo Google,
# service-<PROJECT_NUMBER>@gcp-sa-dataform.iam.gserviceaccount.com) — desligado
# por padrão; ligue por projeto conforme o Dataform for habilitado nele.
dataform_service_agent = {
  enabled                         = true
  execution_service_account_email = "sa-df-meuproduto@prj-meuproduto-mdl-prd.iam.gserviceaccount.com"
  kms_project_id                  = "prj-hsm-services-prd" # omita/null se não usa CMEK externo
}
