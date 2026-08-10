resource "google_project_iam_member" "permissions_sa_composer" {
  for_each = var.permissions_sa_composer

  project       = var.iam_settings["iam"].project_id
  role          = each.value
  member        = "serviceAccount:${google_service_account.sa["sa-comp"].email}"
   
}