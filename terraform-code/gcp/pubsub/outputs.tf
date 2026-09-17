output "pubsub_topics" {
  description = "Tópicos Pub/Sub criados, indexados pela mesma chave de var.pubsub_topic_settings."
  value = {
    for key, topic in google_pubsub_topic.topic : key => {
      id           = topic.id
      name         = topic.name
      project      = topic.project
      kms_key_name = topic.kms_key_name
    }
  }
}

output "pubsub_subscriptions" {
  description = "Assinaturas Pub/Sub criadas, indexadas pela mesma chave de var.pubsub_settings."
  value = {
    for key, sub in google_pubsub_subscription.subs : key => {
      id      = sub.id
      name    = sub.name
      project = sub.project
      topic   = sub.topic
    }
  }
}
