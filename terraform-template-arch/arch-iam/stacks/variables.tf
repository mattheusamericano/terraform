#
#IAM
#
variable "iam_settings"{
  type = map(object({
    project_id                                  = string
    }))
}

#
#SERVICE_ACCOUNT
#
variable "sa_settings"{
  type = map(object({
    project_id                          = string
    display_name                        = string
    sigla                               = string  
    }))
}


#
#Grupos para Custom Roles
#
variable "ml_engineer_org_group" {
  type    = string
  default = null
}
variable "ml_data_scientist_org_group" {
  type    = string
  default = null
}
variable "data_engineer_org_group" {
  type    = string
  default = null
}