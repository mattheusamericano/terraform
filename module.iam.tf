module "iam" {
  depends_on = [
    module.apis,
#    module.artifact_registry
  ]
  source                        = "./modules/iam"
  project_id                    = var.project_id
  bigquery_dataform_permissions = var.bigquery_dataform_permissions
  ml_viewer_permissions         = var.ml_viewer_permissions
  ml_engineer_permissions       = var.ml_engineer_permissions
  data_engineer_permissions     = var.data_engineer_permissions
  ml_data_scientist_permissions = var.ml_data_scientist_permissions
  ml_data_scientist_org_group   = var.ml_data_scientist_org_group
  ml_engineer_org_group         = var.ml_engineer_org_group
  data_engineer_org_group       = var.data_engineer_org_group
  gcp_project_automate          = var.gcp_project_automate
  network_project_id            = var.network_project_id
  region                        = var.region
  key_crypto                    = var.key_crypto
  key_ring                      = var.key_ring
  name_subnet_vpc_shared        = var.name_subnet_vpc_shared
  kms_project_id                = var.kms_project_id
  repository_python_name        = var.repository_python_name
  workbench_members             = var.workbench_members
  sm_app_id                     = var.sm_app_id
  sm_installation_id            = var.sm_installation_id
  sm_key_pem                    = var.sm_key_pem
  project_number                = var.project_number
}
