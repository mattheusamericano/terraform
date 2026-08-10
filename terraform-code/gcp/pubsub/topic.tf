resource "google_pubsub_topic" "topic" {
for_each = var.pubsub_topic_settings

  project       = each.value["project_id"]
  name          = "${each.key}-${each.value.sigla}-${terraform.workspace}"
}