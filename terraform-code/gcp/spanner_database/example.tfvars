# DDL abaixo é placeholder genérico. Cada elemento da lista é uma statement DDL
# separada (Terraform envia como CreateDatabase/UpdateDatabaseDdl statements).
# Ajuste os nomes de tabela/colunas quando o schema real de cache/auditoria
# estiver definido.

spanner_database_settings = {
  cache_decisao = {
    sigla         = "sipml"
    project_id    = "prj-sipml-gateway-prd"
    instance_name = "hub_decision_broker_sipml_prd" # viria do output do spanner-instance

    database_dialect = "GOOGLE_STANDARD_SQL"
    ddl = [
      <<-EOT
      CREATE TABLE decision_cache (
        cache_key     STRING(MAX) NOT NULL,
        payload       JSON,
        created_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
        expires_at    TIMESTAMP
      ) PRIMARY KEY (cache_key)
      EOT
    ]

    iam_bindings = {
      database_admins  = ["group:gcp-sipml-devops@caixa.gov.br"]
      database_users   = ["serviceAccount:decision-broker-run@prj-sipml-gateway-prd.iam.gserviceaccount.com"]
      database_readers = []
    }
  }

  auditoria_transacional = {
    sigla         = "sipml"
    project_id    = "prj-sipml-gateway-prd"
    instance_name = "hub_decision_broker_sipml_prd"

    database_dialect         = "GOOGLE_STANDARD_SQL"
    deletion_protection      = true
    version_retention_period = "7d" # auditoria pede retenção maior que o cache
    ddl = [
      <<-EOT
      CREATE TABLE audit_log (
        request_id    STRING(36) NOT NULL,
        gn_origem     STRING(50),
        payload       JSON,
        logged_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true)
      ) PRIMARY KEY (request_id)
      EOT
    ]

    iam_bindings = {
      database_admins  = ["group:gcp-sipml-devops@caixa.gov.br"]
      database_users   = ["serviceAccount:decision-broker-run@prj-sipml-gateway-prd.iam.gserviceaccount.com"]
      database_readers = ["group:gcp-sipml-auditoria@caixa.gov.br"]
    }
  }
}
