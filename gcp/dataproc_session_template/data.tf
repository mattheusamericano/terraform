# Necessário para montar o email do service agent do Dataproc quando é preciso
# conceder acesso à chave KMS usada em execution_settings.kms_key.
data "google_project" "kms_target" {
  for_each = {
    for k, v in var.session_template_settings :
    k => v if v.grant_kms_encrypter_decrypter && v.execution_settings.kms_key != null
  }

  project_id = each.value.project_id
}
