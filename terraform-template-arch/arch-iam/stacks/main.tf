#
#IAM
#
module "iam" {
    source      = "../../tf-modules-for-gcp/iam"
    iam_settings                      = {for k, v in var.iam_settings : k => merge(v, { labels = local.common_labels }) }
    sa_settings                       = var.sa_settings
    permissions_sa_global             = local.permissions_sa_global
    permissions_sa_composer           = local.permissions_sa_composer
    permissions_bigquery_dataform     = local.permissions_bigquery_dataform
    permissions_ml_viewer             = local.permissions_ml_viewer
    permissions_ml_engineer           = local.permissions_ml_engineer
    permissions_data_engineer         = local.permissions_data_engineer
    permissions_ml_data_scientis      = local.permissions_ml_data_scientis
    ml_engineer_org_group             = var.ml_engineer_org_group
    ml_data_scientist_org_group       = var.ml_data_scientist_org_group
    data_engineer_org_group           = var.data_engineer_org_group
}
