# ============================================================
# Variables - GKE Nodepool Module
# ============================================================

variable "gke_nodepool_settings" {
  type = map(object({
    project_id   = string
    region       = string
    sigla        = string
    cluster_name = string   # output do módulo cluster
    gke_sa_email = string   # output do módulo cluster (gke_sa_emails)

    # Sizing
    machine_type = optional(string, "e2-standard-4")
    disk_type    = optional(string, "pd-ssd")
    disk_size_gb = optional(number, 100)

    # Autoscaling
    min_node_count = optional(number, 1)
    max_node_count = optional(number, 3)

    # Taints opcionais
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string   # NO_SCHEDULE, PREFER_NO_SCHEDULE, NO_EXECUTE
    })), [])

    labels = optional(map(string), {})
  }))
}
