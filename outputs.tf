# ============================================================
# Outputs - Cloud SQL Module
# ============================================================

output "instance_name" {
  description = "Nome da instância Cloud SQL"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "Connection name para uso com Cloud SQL Auth Proxy"
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip_address" {
  description = "IP privado da instância (use para comunicação interna na VPC)"
  value       = google_sql_database_instance.main.private_ip_address
}

output "instance_self_link" {
  description = "Self-link da instância"
  value       = google_sql_database_instance.main.self_link
}

output "read_replica_connection_names" {
  description = "Connection names das read replicas"
  value       = [for r in google_sql_database_instance.read_replica : r.connection_name]
}

output "read_replica_private_ips" {
  description = "IPs privados das read replicas"
  value       = [for r in google_sql_database_instance.read_replica : r.private_ip_address]
}

output "sql_proxy_service_account_email" {
  description = "E-mail do service account do Cloud SQL Proxy"
  value       = var.create_proxy_service_account ? google_service_account.sql_proxy_sa[0].email : null
}

output "private_ip_range_name" {
  description = "Nome do range de IPs privados reservados para o peering"
  value       = google_compute_global_address.private_ip_range.name
}
