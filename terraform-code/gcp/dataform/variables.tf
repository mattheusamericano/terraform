variable "dataform_repository_settings" {
  type = map(object({
    project_id         = string
    region             = string
    sigla              = string
    service_account_id = string
    git_url            = optional(string)
    git_default_branch = optional(string)
    git_secret_version = optional(string)
    labels             = map(any)

    # Nome completo da chave KMS (CMEK) usada pra criptografar o repositório
    # e os recursos filhos (compilationResults, workflowInvocations, ...) —
    # ex.: "projects/prj-hsm-services-prd/locations/southamerica-east1/keyRings/kr-x/cryptoKeys/key-x".
    # Deixe null (padrão) se este repositório não usa CMEK. Quando definido,
    # o módulo concede automaticamente roles/cloudkms.cryptoKeyEncrypterDecrypter
    # ao Dataform Service Agent na própria chave (ver iam.tf).
    kms_key_name = optional(string, null)

    # Tempo de espera após conceder roles/cloudkms.cryptoKeyEncrypterDecrypter
    # ao Dataform Service Agent, antes de criar/atualizar o repositório —
    # propagação de IAM não é instantânea; sem essa espera o apply pode falhar
    # de forma intermitente por permissão. Só tem efeito quando kms_key_name
    # está definido.
    iam_propagation_wait = optional(string, "60s")
  }))
}