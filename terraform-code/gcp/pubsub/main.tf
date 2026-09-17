resource "google_pubsub_subscription" "subs" {
for_each = var.pubsub_settings

  project                       = each.value["project_id"]
  name                          = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  topic                         = each.value["topic_name"]
  labels                        = each.value["labels"]

  ack_deadline_seconds          = each.value["ack_deadline_seconds"]
  message_retention_duration    = each.value["message_retention_duration"]
  retain_acked_messages         = each.value["retain_acked_messages"]

  depends_on = [google_pubsub_topic.topic]
}