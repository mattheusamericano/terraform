variable "sa_settings"{
  type = map(object({
    project_id                          = string
    display_name                        = string 
    sigla                               = string   
    }))
}

variable "iam_settings"{
  type = map(object({
    project_id                                  = string
    }))
}

variable "permissions_sa_global" {
    type = map(string)
}
variable "permissions_sa_composer" {
    type = map(string)
}
variable "permissions_bigquery_dataform" {
    type = list(string)
}
variable "permissions_ml_viewer" {
    type = list(string)
}
variable "permissions_ml_engineer" {
    type = list(string)
}
variable "permissions_data_engineer" {
    type = list(string)
}
variable "permissions_ml_data_scientis" {
    type = list(string)
}

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