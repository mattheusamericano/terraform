resource "google_project_iam_binding" "machine_learning_engineer_project_group_binding" {
  project = var.iam_settings["iam"].project_id
  role    = google_project_iam_custom_role.machine_learning_engineer.name
  members = [
    var.ml_engineer_org_group,
  ]
}

#resource "google_project_iam_binding" "machine_learning_google_role" {
#  project = var.iam_settings["iam"].project_id
#  role    = "roles/iam.mlEngineer"
#  members = [
#    var.ml_engineer_org_group,
#  ]
#}

resource "google_project_iam_binding" "machine_learning_google_noteviwer" {
  project = var.iam_settings["iam"].project_id
  role    = "roles/notebooks.runner"
  members = [
    var.ml_data_scientist_org_group,
    var.data_engineer_org_group

  ]
}

resource "google_project_iam_binding" "ml_data_scientist_project_group_binding" {
  project = var.iam_settings["iam"].project_id
  role    = google_project_iam_custom_role.machine_learning_data_scientist.name
  members = [
    var.ml_data_scientist_org_group,
  ]
}

resource "google_project_iam_binding" "data_engineer_project_group_binding" {
  project = var.iam_settings["iam"].project_id
  role    = google_project_iam_custom_role.data_engineer.name
  members = [
    var.data_engineer_org_group,
  ]
}