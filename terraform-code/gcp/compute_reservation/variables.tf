variable "compute_reservations_settings"{
  type = map(object({
    project_id                          = string
    region                              = string
    zone                                = string
    sigla                               = string
    count_rv                            = number
    rv_machine_type                     = optional(string)
    rv_accelerator_type                 = optional(string)
    rv_accelerator_count                = optional(number)    
    labels                              = map(any)
    }))
}
