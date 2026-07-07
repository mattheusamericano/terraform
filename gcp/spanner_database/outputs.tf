output "database_names" {
  description = "Mapa chave => nome real do database"
  value       = { for k, v in google_spanner_database.this : k => v.name }
}

output "database_ids" {
  description = "Mapa chave => id completo do database"
  value       = { for k, v in google_spanner_database.this : k => v.id }
}
