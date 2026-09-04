variable "workbench_settings" {
  type = map(object({
    project_id                = string
    region                    = string
    zone                      = string
    sigla                     = string
    network_project_id        = string
    kms_project_id            = string
    workbench_machine_type    = string
    workbench_disk_size_gb    = string
    workbench_disk_type       = string
    workbench_disk_encryption = string
    key_ring                  = string
    key_crypto                = string
    name_vpc_shared           = string
    name_subnet_vpc_shared    = string
    repository_name           = optional(string)
    workbench_members         = optional(list(string))
    sa_account_id             = string
    auto_shutdown             = optional(string, "3600")
    labels                    = map(any)

    # Conjunto de roles da SA no PRÓPRIO projeto (project_id acima). null (padrão)
    # usa o conjunto padrão do módulo (local._sa_base_project_roles, em locals.tf)
    # — informe uma lista aqui pra SUBSTITUIR esse padrão inteiro só para este
    # Workbench, em vez de só adicionar a ele (para adicionar sem substituir, use
    # extra_project_roles abaixo).
    project_roles = optional(list(string), null)

    # Roles adicionais da SA no próprio projeto, somadas ao conjunto efetivo
    # (project_roles, se informado, senão o padrão do módulo).
    extra_project_roles = optional(list(string), [])

    # Roles concedidas à SA deste Workbench em projetos DIFERENTES do project_id
    # dela (aditivo via google_project_iam_member, um resource por combinação de
    # projeto+role). Quem roda o apply precisa já ter permissão de conceder IAM
    # em cada project_id listado aqui (fora do escopo deste módulo).
    #
    # Default = o grant que antes era fixo no código (roles/bigquery.dataViewer
    # em bigdata-1744049006) — preserva o comportamento histórico do módulo sem
    # exigir ajuste em .tfvars já existentes. Informe uma lista aqui pra
    # SUBSTITUIR esse default inteiro (inclusive [] pra remover o grant nesta
    # instância) ou pra adicionar mais entradas além dele.
    cross_project_roles = optional(list(object({
      project_id = string
      role       = string
      })), [
      { project_id = "bigdata-1744049006", role = "roles/bigquery.dataViewer" },
    ])


    wb_reservation_name    = optional(string)
    wbrv_machine_type      = optional(string)
    wbrv_accelerator_type  = optional(string)
    wbrv_accelerator_count = optional(number)
  }))
}
