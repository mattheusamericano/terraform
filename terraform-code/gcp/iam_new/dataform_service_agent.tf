# Habilitado por var.dataform_service_agent.enabled (true/false por projeto). O número do
# projeto é necessário pra montar a identidade do Dataform Service Agent
# (service-<PROJECT_NUMBER>@gcp-sa-dataform.iam.gserviceaccount.com) e só existe depois de a
# API dataform.googleapis.com estar habilitada em var.project_id.
data "google_project" "dataform_service_agent" {
  count = var.dataform_service_agent.enabled ? 1 : 0

  project_id = var.project_id
}

locals {
  dataform_service_agent_member = var.dataform_service_agent.enabled ? "serviceAccount:service-${data.google_project.dataform_service_agent[0].number}@gcp-sa-dataform.iam.gserviceaccount.com" : null
}

# Impersonação da SA de execução do Dataform — binding NA PRÓPRIA SA, não no projeto.
resource "google_service_account_iam_member" "dataform_service_agent_token_creator" {
  count = var.dataform_service_agent.enabled ? 1 : 0

  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.dataform_service_agent.execution_service_account_email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = local.dataform_service_agent_member
}

resource "google_service_account_iam_member" "dataform_service_agent_user" {
  count = var.dataform_service_agent.enabled ? 1 : 0

  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.dataform_service_agent.execution_service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = local.dataform_service_agent_member
}

# Developer Connect: necessário pro Dataform acessar o repositório Git via Secure Source Connection.
resource "google_project_iam_member" "dataform_service_agent_git_proxy" {
  count = var.dataform_service_agent.enabled ? 1 : 0

  project = var.project_id
  role    = "roles/developerconnect.gitProxyUser"
  member  = local.dataform_service_agent_member
}

resource "google_project_iam_member" "dataform_service_agent_token_accessor" {
  count = var.dataform_service_agent.enabled ? 1 : 0

  project = var.project_id
  role    = "roles/developerconnect.tokenAccessor"
  member  = local.dataform_service_agent_member
}

# KMS externo (opcional): só quando o Dataform usa uma chave CMEK de um projeto diferente do
# próprio var.project_id (ex.: um projeto central de KMS compartilhado).
resource "google_project_iam_member" "dataform_service_agent_kms" {
  count = var.dataform_service_agent.enabled && var.dataform_service_agent.kms_project_id != null ? 1 : 0

  project = var.dataform_service_agent.kms_project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = local.dataform_service_agent_member
}
