resource "google_dataform_repository" "repository" {
  for_each = var.dataform_repository_settings

  provider        = google-beta
  name            = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  display_name    = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  project         = each.value["project_id"]
  region          = each.value["region"]
  labels          = each.value["labels"]
  deletion_policy = "FORCE"
  service_account = google_service_account.dataform_sa[each.key].email
  kms_key_name    = each.value.kms_key_name

  dynamic "git_remote_settings" {
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

  # Garante que o Dataform Service Agent já tem permissão na chave KMS (e que
  # essa permissão já propagou) antes de criar/atualizar o repositório —
  # ver time_sleep.iam_propagation em iam.tf.
  depends_on = [time_sleep.iam_propagation]
}