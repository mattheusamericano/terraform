variable "cloud_run_settings" {

  description = "Cloud Run Settings"

  type = map(object({
    project_id    = string
    region        = string
    sigla         = string
    image         = string
    cpu           = string
    memory        = string
    max_scale     = number
    vpc_connector = optional(string)
    invoker       = optional(string)
    sa_account_id = string
    labels = map(any)
    network_project_id     = optional(string)
    name_subnet_vpc_shared = optional(string) 
    kms_project_id = optional(string, null)
    key_ring       = optional(string, null)
    key_crypto     = optional(string, null)

  }))
}