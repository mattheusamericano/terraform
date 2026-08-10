output "instance_names" {
  description = "Mapa chave => nome real da instância (para encadeamento com o módulo spanner-database)"
  value       = { for k, v in google_spanner_instance.this : k => v.name }
}

output "instance_ids" {
  description = "Mapa chave => id completo da instância"
  value       = { for k, v in google_spanner_instance.this : k => v.id }
}

output "instance_configs" {
  description = "Mapa chave => config (região/multi-região) usada"
  value       = { for k, v in google_spanner_instance.this : k => v.config }
}
