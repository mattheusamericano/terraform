locals {
  pubsub_topic_kms_key_names = {
    for key, value in var.pubsub_topic_settings : key => (
      value.kms_key_ring != null
      ? "projects/${value.kms_project_id}/locations/${value.region}/keyRings/${value.kms_key_ring}/cryptoKeys/${value.kms_crypto_key}"
      : null
    )
  }
}
