variable "colab_runtime_template_settings" {
    type = map(object({
      project_id                          = string
      region                              = string
      sigla                               = string
      machine_type                        = string
      accelerator_type                    = optional(string)
      accelerator_count                   = optional(string)
      disk_type                           = string
      disk_size_gb                        = number
      network_project_id                  = string
      name_vpc_shared                     = string
      name_subnet_vpc_shared              = string
      labels                              = map(any)
      runtime_user                        = optional(string)
      runtime_name                        = optional(string)

    }))
}