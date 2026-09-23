locals {
  colab_runtime_template_kms_key_names = {
    for key, value in var.colab_runtime_template_settings : key => (
      value.kms_key_ring != null
      ? "projects/${value.kms_project_id}/locations/${value.region}/keyRings/${value.kms_key_ring}/cryptoKeys/${value.kms_crypto_key}"
      : null
    )
  }

  colab_runtime_template_cmek_pairs = distinct([
    for key, value in var.colab_runtime_template_settings :
    "${value.project_id}|${local.colab_runtime_template_kms_key_names[key]}"
    if local.colab_runtime_template_kms_key_names[key] != null
  ])

  colab_runtime_template_cmek_bindings = {
    for pair in local.colab_runtime_template_cmek_pairs : pair => {
      project_id   = split("|", pair)[0]
      kms_key_name = split("|", pair)[1]
    }
  }

  colab_runtime_template_cmek_projects = toset([
    for binding in local.colab_runtime_template_cmek_bindings : binding.project_id
  ])
}
