variable "roks_worker_pool_settings" {
  description = "Mapa de configuracao de worker pools adicionais para clusters ROKS ja existentes. Cada chave representa um worker pool logico."

  type = map(object({
    cluster_id        = string # ID do cluster ROKS (ex: modulo roks_cluster output.cluster_ids)
    vpc_id            = string # mesma VPC do cluster
    resource_group_id = optional(string, null)

    flavor       = string              # perfil de maquina dos workers deste pool (ex: "bx2.8x32")
    worker_count = optional(number, 2) # workers por zona

    zones = list(object({
      name      = string
      subnet_id = string
    }))

    labels = optional(map(string), {})

    taints = optional(list(object({
      key    = string
      value  = string
      effect = string # NoSchedule | PreferNoSchedule | NoExecute
    })), [])

    entitlement = optional(string, null) # "cloud_pak" se a licenca do OpenShift vier de um Cloud Pak ja possuido
  }))
}
