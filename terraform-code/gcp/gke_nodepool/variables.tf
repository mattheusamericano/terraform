variable "gke_nodepool_settings" {
  type = map(object({
    project_id   = string
    region       = string
    zone         = string
    sigla        = string
    cluster_name = string   # output do módulo cluster
    gke_sa_email = string   # output do módulo cluster (gke_sa_emails)

    machine_type        = optional(string, "e2-standard-4")
    max_pods_per_node   = optional(number, 200)
    disk_type           = optional(string, "pd-ssd")
    disk_size_gb        = optional(number, 100)

    min_node_count = optional(number, 1)
    max_node_count = optional(number, 2)

    taint_value    = string

    labels = optional(map(string), {})
  }))
}