sa_settings = {
  "sa-app" = {
    project_id   = "prj-app-des"
    sigla        = "eng"
    display_name = "Service Account da aplicação X"
    description  = "Usada pela aplicação X para acessar Cloud SQL e Pub/Sub"

    roles = [
      "roles/cloudsql.client",
      "roles/pubsub.publisher",
    ]
  }

  "sa-etl" = {
    project_id = "prj-app-des"
    sigla      = "eng"
    # display_name e description ficam com o default do módulo

    roles = [
      "roles/bigquery.jobUser",
      "roles/bigquery.dataEditor",
      "roles/storage.objectAdmin",
    ]
  }

  "sa-readonly" = {
    project_id = "prj-app-des"
    sigla      = "eng"
    # sem roles: só cria a identidade, sem nenhuma permissão de projeto
  }

  "sa-dataform" = {
    project_id = "prj-modelagem-des"
    sigla      = "eng"

    roles = [
      "roles/dataform.editor",
    ]

    # roles em projetos diferentes de prj-modelagem-des
    cross_project_roles = [
      { project_id = "prj-hsm-services-prd", role = "roles/cloudkms.cryptoKeyEncrypterDecrypter" },
      { project_id = "prj-bigdata-compartilhado", role = "roles/bigquery.dataViewer" },
    ]
  }
}
