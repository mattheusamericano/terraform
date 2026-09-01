variable "project_id" {
  description = "Projeto GCP onde todos os recursos de IAM deste módulo serão criados."
  type        = string

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id não pode ser vazio."
  }
}

#
# CUSTOM ROLES
#
variable "custom_roles" {
  description = "Roles customizadas de projeto a criar. A chave do mapa é a referência estável usada em iam_bindings através do valor \"custom:<chave>\"."
  type = map(object({
    role_id     = string
    title       = string
    description = optional(string, "")
    permissions = list(string)
    stage       = optional(string, "GA")
  }))
  default = {}
}

#
# DATAFORM SERVICE AGENT
#
variable "dataform_service_agent" {
  description = <<-EOT
    Concede as permissões que o Dataform Service Agent (identidade gerenciada pelo Google, provisionada
    quando dataform.googleapis.com é habilitada em var.project_id, no formato
    "service-<PROJECT_NUMBER>@gcp-sa-dataform.iam.gserviceaccount.com") precisa pra operar:
      - Impersonar a SA de execução do Dataform (roles/iam.serviceAccountTokenCreator +
        roles/iam.serviceAccountUser, concedidos NA PRÓPRIA SA informada em
        execution_service_account_email, não em var.project_id).
      - Usar Developer Connect pra acessar o repositório Git via Secure Source Connection
        (roles/developerconnect.gitProxyUser + roles/developerconnect.tokenAccessor, em var.project_id).
      - Se houver, descriptografar com uma chave KMS de um projeto externo
        (roles/cloudkms.cryptoKeyEncrypterDecrypter, em kms_project_id).
    O número do projeto é resolvido via data.google_project — não precisa ser informado.
  EOT
  type = object({
    enabled                         = optional(bool, false)
    execution_service_account_email = optional(string, null) # e-mail da SA de execução do Dataform — obrigatório quando enabled = true
    kms_project_id                  = optional(string, null) # projeto dono da chave KMS usada pelo Dataform, se houver (ex.: prj-hsm-services-prd) — omita/null se não usa CMEK externo
  })
  default = {}

  validation {
    condition     = !var.dataform_service_agent.enabled || var.dataform_service_agent.execution_service_account_email != null
    error_message = "dataform_service_agent.execution_service_account_email é obrigatório quando dataform_service_agent.enabled = true."
  }
}

#
# GRANTS
#
variable "iam_bindings" {
  description = <<-EOT
    Concede uma role (predefinida "roles/x" ou customizada "custom:<chave>") a uma lista de membros
    (formato completo do GCP, ex.: "group:x@dominio.com", "serviceAccount:x@projeto.iam.gserviceaccount.com",
    "user:x@dominio.com"). Este módulo não cria Service Accounts nem nenhuma outra identidade — quem for
    Service Account deve já existir (tipicamente criada pelo módulo "service_account" ou por um módulo de
    recurso específico) e ser referenciada aqui pelo seu e-mail.
    Por padrão usa google_project_iam_member (aditivo e seguro: não afeta outros membros da mesma role).
    Definir authoritative = true faz esse binding usar google_project_iam_binding, que é AUTORITATIVO e
    substitui TODOS os membros da role a cada apply — use apenas quando isso for intencional, pois qualquer
    membro adicionado fora do Terraform (manualmente ou por outro processo) será removido no próximo apply.
  EOT
  type = map(object({
    role          = string
    members       = list(string)
    authoritative = optional(bool, false)
  }))
  default = {}
}
