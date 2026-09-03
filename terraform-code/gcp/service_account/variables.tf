variable "sa_settings" {
  description = "Mapa de Service Accounts a serem criadas, uma entrada por conta. A chave do mapa é usada como parte do account_id."
  type = map(object({
    project_id   = string
    sigla        = string
    display_name = optional(string)
    description  = optional(string, "Service Account gerenciada via Terraform")
    disabled     = optional(bool, false)

    # Roles de projeto concedidas a esta SA (aditivo via google_project_iam_member),
    # sempre no mesmo project_id da SA. Cada SA do mapa pode ter uma lista de roles
    # diferente.
    roles = optional(list(string), [])

    # Roles concedidas a esta SA em projetos DIFERENTES do project_id da SA (aditivo
    # via google_project_iam_member, um resource por combinação de projeto+role).
    # Ex.: uma SA em prj-modelagem que precisa de roles/cloudkms.cryptoKeyEncrypterDecrypter
    # em prj-hsm-services-prd. Quem roda o apply precisa já ter permissão de conceder
    # IAM em cada project_id listado aqui (fora do escopo deste módulo).
    cross_project_roles = optional(list(object({
      project_id = string
      role       = string
    })), [])
  }))
}
