output "cluster_names" {
  description = "Nome de cada cluster criado, por chave do mapa de entrada."
  value       = { for k, v in google_dataproc_cluster.this : k => v.name }
}

output "cluster_ids" {
  description = "ID (self_link) de cada cluster criado, por chave do mapa de entrada."
  value       = { for k, v in google_dataproc_cluster.this : k => v.id }
}

output "cluster_staging_buckets" {
  description = "Bucket de staging efetivamente usado por cada cluster."
  value       = { for k, v in google_dataproc_cluster.this : k => v.cluster_config[0].bucket }
}

output "cluster_service_accounts" {
  description = "Email da Service Account dedicada criada para cada cluster."
  value       = { for k, v in google_service_account.cluster : k => v.email }
}
