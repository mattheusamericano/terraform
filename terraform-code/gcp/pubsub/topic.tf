resource "google_pubsub_topic" "topic" {
for_each = var.pubsub_topic_settings

  project       = each.value["project_id"]
  name          = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  labels        = each.value["labels"]
  kms_key_name  = local.pubsub_topic_kms_key_names[each.key]

  depends_on = [google_kms_crypto_key_iam_member.pubsub]
}