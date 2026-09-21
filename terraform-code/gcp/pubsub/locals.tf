locals {
  pubsub_topic_kms_key_names = {
    for key, value in var.pubsub_topic_settings : key => (
      value.kms_key_ring != null
      ? "projects/${value.kms_project_id}/locations/${value.region}/keyRings/${value.kms_key_ring}/cryptoKeys/${value.kms_crypto_key}"
      : null
    )
  }

  pubsub_cmek_pairs = distinct([
    for key, value in var.pubsub_topic_settings :
    "${value.project_id}|${local.pubsub_topic_kms_key_names[key]}"
    if local.pubsub_topic_kms_key_names[key] != null
  ])

  pubsub_cmek_bindings = {
    for pair in local.pubsub_cmek_pairs : pair => {
      project_id   = split("|", pair)[0]
      kms_key_name = split("|", pair)[1]
    }
  }

  pubsub_cmek_projects = toset([
    for binding in local.pubsub_cmek_bindings : binding.project_id
  ])
}
