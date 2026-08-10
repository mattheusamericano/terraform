spanner_instance_settings = {
  hub_decision_broker = {
    sigla            = "sipml"
    project_id       = "prj-sipml-gateway-prd"
    config           = "regional-southamerica-east1"
    processing_units = 1000
    edition          = "STANDARD"
    labels = {
      camada = "hub"
      uso    = "decision-broker"
    }
    iam_bindings = {
      admins          = ["group:gcp-sipml-admins@caixa.gov.br"]
      database_admins = ["group:gcp-sipml-devops@caixa.gov.br"]
      viewers         = []
    }
  }
}
