variable "roks_cluster_settings" {
  description = "Mapa de configuracao dos clusters Red Hat OpenShift on IBM Cloud (ROKS) em VPC. Cada chave representa um cluster logico. O modulo NAO cria VPC/subnets - eles precisam ja existir."

  type = map(object({
    sigla             = string
    resource_group_id = string # tambem usado para escopar o IAM deste cluster (ver iam_bindings)
    vpc_id            = string # VPC ja existente onde o cluster sera criado

    flavor       = string                 # perfil de maquina dos workers do pool default (ex: "bx2.4x16")
    kube_version = optional(string, null) # ex: "4.15_openshift". null usa a versao default do offering
    worker_count = optional(number, 2)    # workers por zona, no pool default

    # Zonas da VPC onde o cluster tera workers - 3 zonas e o minimo recomendado para HA em prd
    zones = list(object({
      name      = string # ex: "br-sao-1"
      subnet_id = string # subnet ja existente na VPC, nessa zona
    }))

    cos_instance_crn = string                 # CRN de uma instancia COS (obrigatorio p/ OpenShift - usada p/ registry interno). Ver modulo cos_instance.
    entitlement      = optional(string, null) # "cloud_pak" se a licenca do OpenShift vier de um Cloud Pak ja possuido

    disable_public_service_endpoint = optional(bool, true) # cluster com master privado por padrao
    wait_till                       = optional(string, "IngressReady")

    tags   = optional(list(string), [])
    labels = optional(map(string), {}) # aplicadas ao worker pool default (worker_labels)

    # IAM: concede acesso a TODOS os clusters ROKS dentro do resource_group_id
    # deste cluster (ver Observacoes no README sobre o escopo real do binding).
    iam_bindings = optional(object({
      managers  = optional(list(string), []) # access groups com roles/Manager
      operators = optional(list(string), []) # access groups com roles/Operator
      viewers   = optional(list(string), []) # access groups com roles/Viewer
    }), {})
  }))
}
