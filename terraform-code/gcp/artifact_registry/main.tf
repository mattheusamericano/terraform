resource "google_artifact_registry_repository" "artifact_registry" {
  for_each = var.artifact_registry_settings

  repository_id                 = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  cleanup_policy_dry_run        = each.value["cleanup_policy_dry_run"]
  format                        = each.value["artifact_format"]
  location                      = each.value["region"]
  mode                          = each.value["artifact_mode"]
  project                       = each.value["project_id"]
  labels                        = each.value["labels"]
  description                   = each.value["description"]
  kms_key_name                  = local.artifact_registry_kms_key_names[each.key]

  depends_on = [google_kms_crypto_key_iam_member.artifact_registry]
}