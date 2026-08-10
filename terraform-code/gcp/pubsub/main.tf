resource "google_pubsub_subscription" "subs" {
for_each = var.pubsub_settings

  project                       = each.value["project_id"]
  name                          = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  topic                         = each.value["topic_name"]
  labels                        = each.value["labels"]

  ack_deadline_seconds          = 20
  message_retention_duration    = "1200s"
  retain_acked_messages         = true
  
  depends_on = [google_pubsub_topic.topic]
}