# ============================================================
# Analytics Hub - Outputs
# ============================================================

output "exchange_ids" {
  description = "IDs dos Data Exchanges criados, indexados pela chave do mapa"
  value = {
    for k, v in google_bigquery_analytics_hub_data_exchange.exchange : k => v.id
  }
}

output "exchange_names" {
  description = "data_exchange_id de cada Exchange (usado para referenciar em outros módulos)"
  value = {
    for k, v in google_bigquery_analytics_hub_data_exchange.exchange : k => v.data_exchange_id
  }
}