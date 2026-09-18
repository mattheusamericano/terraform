access_policy_id = "412713748361"
perimeter_name   = "perimetroprojetoscaixa"

# Regra de EGRESS: permite que qualquer Service Account dentro do perímetro acesse o
# Cloud KMS no projeto prj-hsm-services-prd, que fica FORA do perímetro (cenário comum
# quando a chave CMEK vive num projeto central de KMS, como nos módulos artifact_registry/pubsub).
egress_policies = {
  acesso-cmek-hsm-prd = {
    egress_from = {
      identity_type = "ANY_SERVICE_ACCOUNT"
    }
    egress_to = {
      resources = ["projects/999999999999"] # project NUMBER (não project_id) do prj-hsm-services-prd
      operations = [
        {
          service_name = "cloudkms.googleapis.com"
          method_selectors = [
            { method = "*" },
          ]
        }
      ]
    }
  }
}

# Regra de INGRESS: permite que uma Service Account específica, de fora do perímetro
# (ex.: um projeto de CI/CD), acesse o BigQuery de qualquer recurso dentro do perímetro.
ingress_policies = {
  cicd-acessa-bigquery = {
    ingress_from = {
      identity_type = "ANY_SERVICE_ACCOUNT"
      identities    = ["serviceAccount:sa-cicd@prj-cicd-prd.iam.gserviceaccount.com"]
      sources = [
        { resource = "projects/111111111111" }, # project NUMBER do prj-cicd-prd
      ]
    }
    ingress_to = {
      resources = ["*"]
      operations = [
        {
          service_name = "bigquery.googleapis.com"
          method_selectors = [
            { method = "*" },
          ]
        }
      ]
    }
  }
}
