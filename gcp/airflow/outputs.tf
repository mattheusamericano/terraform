# ============================================================
# Cloud Composer 3 - Outputs
# ============================================================

output "project_numbers" {
  description = "Project numbers capturados via data source (útil para debug e referência)"
  value = {
    for k, v in data.google_project.service :
    k => v.number
  }
}

output "composer_environment_names" {
  description = "Nomes dos ambientes Composer criados"
  value = {
    for k, v in google_composer_environment.composer :
    k => v.name
  }
}

output "composer_gcs_buckets" {
  description = "Buckets GCS associados a cada ambiente Composer (DAGs, logs, plugins)"
  value = {
    for k, v in google_composer_environment.composer :
    k => v.config[0].dag_gcs_prefix
  }
}

output "composer_airflow_uris" {
  description = "URLs da interface web do Airflow para cada ambiente"
  value = {
    for k, v in google_composer_environment.composer :
    k => v.config[0].airflow_uri
  }
  sensitive = false
}

output "composer_sa_emails" {
  description = "E-mails das Service Accounts criadas para cada ambiente Composer"
  value = {
    for k, v in google_service_account.composer_sa :
    k => v.email
  }
}

output "composer_sa_ids" {
  description = "IDs únicos das Service Accounts (útil para Workload Identity)"
  value = {
    for k, v in google_service_account.composer_sa :
    k => v.unique_id
  }
}

output "generated_secret_ids" {
  description = "IDs dos secrets gerados pelo Terraform no Secret Manager (um por ambiente/secret_name)"
  value = {
    for k, v in google_secret_manager_secret.generated :
    k => v.secret_id
  }
}

output "generated_secret_names" {
  description = "Nomes completos dos secrets (formato: projects/{project}/secrets/{id}) para referência em outros módulos"
  value = {
    for k, v in google_secret_manager_secret.generated :
    k => v.name
  }
}

output "composer_environment_ids" {
  description = "IDs completos dos recursos Composer (útil para referência entre módulos)"
  value = {
    for k, v in google_composer_environment.composer :
    k => v.id
  }
}
