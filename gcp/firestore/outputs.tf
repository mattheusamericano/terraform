# ============================================================
# Outputs - Firestore Database Module
# ============================================================

output "database_names" {
  description = "Nomes dos databases criados"
  value       = { for k, v in google_firestore_database.database : k => v.name }
}

output "database_ids" {
  description = "IDs dos databases"
  value       = { for k, v in google_firestore_database.database : k => v.id }
}
