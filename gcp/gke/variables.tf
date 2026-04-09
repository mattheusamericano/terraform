# ============================================================
# Variables - GKE Cluster Module
# ============================================================

variable "gke_cluster_settings" {
  type = map(object({
    project_id  = string
    region      = string
    sigla       = string

    # Networking
    network_project_id    = string
    name_vpc_shared       = string
    subnet_name           = string
    master_ipv4_cidr_block = string      # ex: "172.16.0.0/28"
    pods_range_name       = string       # nome do secondary range para pods
    services_range_name   = string       # nome do secondary range para services

    # Master authorized networks
    master_authorized_networks = optional(list(object({
      name = string
      cidr = string
    })), [])

    # KMS (opcional)
    kms_project_id   = optional(string, null)
    kms_keyring_name = optional(string, null)
    kms_key_name     = optional(string, null)

    labels = optional(map(string), {})
  }))
}
