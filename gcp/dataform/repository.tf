resource "google_dataform_repository" "repository" {
  for_each = var.dataform_repository_settings
  
  provider          = google-beta
  name              = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name      = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  project           = each.value["project_id"]
  region            = each.value["region"]
  labels            = each.value["labels"]
  deletion_policy   = "FORCE"
  service_account   = "${google_service_account.dataform_sa[each.key].email}"

  dynamic git_remote_settings {
    for_each = each.value.git_url != null && each.value.git_url != "" ? [1] : []
    
    content {
    url                                 = each.value["git_url"]
    default_branch                      = each.value["git_default_branch"]
    authentication_token_secret_version = each.value["git_secret_version"]
    }
  }

  workspace_compilation_overrides {
    default_database = each.value["project_id"]
  }

}