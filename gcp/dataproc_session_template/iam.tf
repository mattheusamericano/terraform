# Binding aditivo: a chave KMS normalmente pertence a outro projeto, então não é
# "dono" do recurso e usamos google_kms_crypto_key_iam_member em vez de binding autoritativo.
resource "google_kms_crypto_key_iam_member" "session_kms" {
  for_each = data.google_project.kms_target

  crypto_key_id = var.session_template_settings[each.key].execution_settings.kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${each.value.number}@dataproc-accounts.iam.gserviceaccount.com"
}
