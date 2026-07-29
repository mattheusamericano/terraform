variable "cluster_settings" {
  description = "Mapa de definições de clusters Dataproc (HDI/Spark), uma entrada por cluster a provisionar."
  type = map(object({
    sigla      = string
    project_id = string
    region     = string
    zone       = optional(string)

    # Rede (VPC compartilhada) - self_link completo da subnet
    subnetwork        = string
    internal_ip_only  = optional(bool, true)
    tags              = optional(list(string), [])

    service_account         = string
    service_account_scopes  = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])

    master_settings = optional(object({
      machine_type      = optional(string, "n4-standard-2")
      boot_disk_type     = optional(string, "hyperdisk-balanced")
      boot_disk_size_gb  = optional(number, 100)
      num_instances      = optional(number, 1)
    }), {})

    worker_settings = optional(object({
      machine_type      = optional(string, "n4-standard-2")
      boot_disk_type     = optional(string, "hyperdisk-balanced")
      boot_disk_size_gb  = optional(number, 200)
      num_instances      = optional(number, 2)
    }), {})

    image_version             = optional(string, "2.3-debian12")
    optional_components       = optional(list(string), ["JUPYTER"])
    enable_component_gateway  = optional(bool, true)
    override_properties       = optional(map(string), {})
    autoscaling_policy_uri    = optional(string)
    staging_bucket            = optional(string)
    labels                    = optional(map(string), {})

    # IAM - roles/dataproc.viewer + roles/dataproc.editor para a própria SA no próprio projeto
    grant_self_project_dataproc_roles = optional(bool, true)

    # VPC compartilhada - concede roles/compute.networkUser no host project para os
    # service agents do Dataproc (service-<num>@dataproc-accounts / @cloudservices)
    shared_vpc_host_project = optional(string)

    # Bindings adicionais livres (ex.: roles/dataproc.worker para SA em outro projeto)
    additional_project_bindings = optional(map(object({
      project_id = string
      role       = string
      member     = string
    })), {})
  }))
}
