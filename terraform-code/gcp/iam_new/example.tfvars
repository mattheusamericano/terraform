project_id = "prj-meuproduto-mdl-prd"

iam_bindings = {
  # aditivo (padrão) — não remove outros membros já existentes na role
  bq_admin = {
    role    = "roles/bigquery.admin"
    members = ["serviceAccount:sa-meuproduto@prj-meuproduto-mdl-prd.iam.gserviceaccount.com"]
  }

  data_engineer_reader = {
    role    = "roles/bigquery.dataViewer"
    members = ["group:g-data-engineers@empresa.com"]
  }

  # autoritativo (opt-in explícito) — substitui TODOS os membros da role a cada apply
  notebooks_runner = {
    role          = "roles/notebooks.runner"
    members       = ["serviceAccount:sa-notebooks@prj-meuproduto-mdl-prd.iam.gserviceaccount.com"]
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
