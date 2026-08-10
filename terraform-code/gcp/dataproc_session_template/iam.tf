# Binding aditivo: a chave KMS normalmente pertence a outro projeto, então não é
# "dono" do recurso e usamos google_kms_crypto_key_iam_member em vez de binding autoritativo.
resource "google_kms_crypto_key_iam_member" "session_kms" {
  for_each = data.google_project.kms_target

  crypto_key_id = var.dataproc_session_template_settings[each.key].execution_settings.kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${each.value.number}@dataproc-accounts.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "shared_vpc_network_user" {
  for_each = local.shared_vpc_bindings

  project = each.value.host_project
  role    = "roles/compute.networkUser"
  member  = each.value.member
}

# Dá tempo dos bindings acima propagarem antes do Dataproc tentar criar o session
# template usando a subnet/SA. Evita falha intermitente de permissão na criação.
resource "time_sleep" "iam_propagation" {
  for_each = var.dataproc_session_template_settings

  create_duration = each.value.iam_propagation_wait

  depends_on = [
    google_kms_crypto_key_iam_member.session_kms,
    google_project_iam_member.shared_vpc_network_user,
  ]
}
