variable "gke_cluster_settings" {
  type = map(object({
    project_id  = string
    region      = string
    zone        = optional(string)
    sigla       = string

    # Networking
    network_project_id      = string
    name_vpc_shared         = string
    subnet_name             = string
    master_ipv4_cidr_block  = string      # ex: "172.16.0.0/28"
    pods_range_name         = string       # nome do secondary range para pods "192.168.0.0/16"
    services_range_name     = string       # nome do secondary range para services "10.245.0.0/22"
    pods_cidr               = string
    services_cidr           = string

    #System Nodepool
    system_min_node_count   = number
    system_max_node_count   = number
    system_machine_type     = string
    max_pods_per_node       = optional(number, 200)

    # Master authorized networks
    master_authorized_networks = optional(list(object({
      name = string
      cidr = string
    })), [])

    # KMS (opcional)
    kms_project_id    = optional(string, null)
    kms_keyring       = optional(string, null)
    kms_crypto        = optional(string, null)

    labels           = map(any)
  }))
}