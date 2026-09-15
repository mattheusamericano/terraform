module "iam" {
  source   = "../../../terraform-code/gcp/iam_new"
  for_each = var.ml_ops_settings

  project_id = each.value.project_id

  ml_ops_profiles = {
    enabled                     = true
    environment_type            = each.value.environment_type
    ml_engineer_org_group       = each.value.ml_engineer_org_group
    ml_data_scientist_org_group = each.value.ml_data_scientist_org_group
    data_engineer_org_group     = each.value.data_engineer_org_group
  }

  iam_bindings = var.extra_group_role_bindings
}
