variable "workbench_settings"{
  type = map(object({
    project_id                          = string
    region                              = string
    zone                                = string
    sigla                               = string
    network_project_id                  = string  
    kms_project_id                      = string
    workbench_machine_type              = string
    workbench_disk_size_gb              = string
    workbench_disk_type                 = string
    workbench_disk_encryption           = string
    key_ring                            = string
    key_crypto                          = string 
    name_vpc_shared                     = string
    name_subnet_vpc_shared              = string
    repository_name                     = optional(string)
    workbench_members                   = optional(list(string))
    sa_account_id                       = string
    auto_shutdown                       = optional(string, "3600")
    labels                              = map(any)


    wb_reservation_name                 = optional(string) 
    wbrv_machine_type                   = optional(string)
    wbrv_accelerator_type               = optional(string)
    wbrv_accelerator_count              = optional(number) 
    }))
}
