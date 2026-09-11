locals {
  _ml_engineer_roles_nprod = [
    "roles/dataproc.editor",
    "roles/dataplex.catalogEditor",
    "roles/logging.admin",
    "roles/notebooks.runner",
    "roles/compute.viewer",
    "roles/iap.httpsResourceAccessor",
    "roles/run.developer",
    "roles/aiplatform.viewer",
    "roles/iam.roleViewer",
    "roles/cloudbuild.connectionAdmin",
  ]
  _ml_engineer_roles_prod = [
    "roles/dataproc.viewer",
    "roles/dataplex.catalogViewer",
    "roles/logging.viewer",
    "roles/notebooks.viewer",
    "roles/compute.viewer",
    "roles/iap.httpsResourceAccessor",
    "roles/run.viewer",
    "roles/aiplatform.viewer",
    "roles/iam.roleViewer",
  ]

  _ml_data_scientist_roles_nprod = [
    "roles/aiplatform.user",
    "roles/notebooks.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/storage.objectAdmin",
    "roles/artifactregistry.reader",
    "roles/cloudbuild.builds.editor",
    "roles/logging.viewer",
    "roles/dataproc.editor",
    "roles/serviceusage.serviceUsageViewer",
    "roles/iam.roleViewer",
    "roles/iam.dataScientist",
  ]
  _ml_data_scientist_roles_prod = [
    "roles/aiplatform.viewer",
    "roles/notebooks.viewer",
    "roles/bigquery.dataViewer",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader",
    "roles/logging.viewer",
    "roles/dataproc.viewer",
    "roles/serviceusage.serviceUsageViewer",
    "roles/iam.roleViewer",
    "roles/iam.dataScientist",
  ]

  _data_engineer_roles_nprod = [
    "roles/aiplatform.viewer",
    "roles/iam.roleViewer",
    "roles/bigquery.dataEditor",
    "roles/dataform.editor",
    "roles/composer.admin",
    "roles/dataproc.worker",
    "roles/storage.objectAdmin",
    "roles/logging.viewer",
    "roles/iam.mlEngineer",
    "roles/notebooks.runner",
  ]
  _data_engineer_roles_prod = [
    "roles/aiplatform.viewer",
    "roles/iam.roleViewer",
    "roles/bigquery.dataViewer",
    "roles/dataform.viewer",
    "roles/composer.environmentAndStorageObjectViewer",
    "roles/dataproc.viewer",
    "roles/storage.objectViewer",
    "roles/logging.viewer",
  ]

  ml_engineer_roles       = var.ml_ops_profiles.environment_type == "nprod" ? local._ml_engineer_roles_nprod : local._ml_engineer_roles_prod
  ml_data_scientist_roles = var.ml_ops_profiles.environment_type == "nprod" ? local._ml_data_scientist_roles_nprod : local._ml_data_scientist_roles_prod
  data_engineer_roles     = var.ml_ops_profiles.environment_type == "nprod" ? local._data_engineer_roles_nprod : local._data_engineer_roles_prod

  ml_ops_group_role_bindings = !var.ml_ops_profiles.enabled ? {} : merge(
    var.ml_ops_profiles.ml_engineer_org_group == null ? {} : {
      for role in local.ml_engineer_roles : "ml_engineer-${role}" => {
        role   = role
        member = var.ml_ops_profiles.ml_engineer_org_group
      }
    },
    var.ml_ops_profiles.ml_data_scientist_org_group == null ? {} : {
      for role in local.ml_data_scientist_roles : "ml_data_scientist-${role}" => {
        role   = role
        member = var.ml_ops_profiles.ml_data_scientist_org_group
      }
    },
    var.ml_ops_profiles.data_engineer_org_group == null ? {} : {
      for role in local.data_engineer_roles : "data_engineer-${role}" => {
        role   = role
        member = var.ml_ops_profiles.data_engineer_org_group
      }
    },
  )
}

resource "google_project_iam_member" "ml_ops_profile_roles" {
  for_each = local.ml_ops_group_role_bindings

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}
