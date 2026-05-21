variable "sa_settings"{
  type = map(object({
    project_id                          = string
    display_name                        = string    

    }))
}
