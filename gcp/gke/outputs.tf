# ============================================================
# Outputs - GKE Cluster Module
# ============================================================

output "cluster_names" {
  description = "Nomes dos clusters criados"
  value       = { for k, v in google_container_cluster.cluster : k => v.name }
}

output "cluster_endpoints" {
  description = "Endpoints dos clusters"
  value       = { for k, v in google_container_cluster.cluster : k => v.endpoint }
  sensitive   = true
}

output "cluster_ids" {
  description = "IDs dos clusters"
  value       = { for k, v in google_container_cluster.cluster : k => v.id }
}

output "gke_sa_emails" {
  description = "Emails das SAs dos nodes — usar no módulo de nodepool"
  value       = { for k, v in google_service_account.gke_sa : k => v.email }
}

output "cluster_ca_certificates" {
  description = "CA certificates dos clusters"
  value       = { for k, v in google_container_cluster.cluster : k => v.master_auth[0].cluster_ca_certificate }
  sensitive   = true
}
