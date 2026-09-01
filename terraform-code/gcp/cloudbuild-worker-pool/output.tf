output "worker_pool_ids" {
  description = "Mapa {chave => id} dos Cloud Build private worker pools criados."
  value       = { for key, pool in google_cloudbuild_worker_pool.this : key => pool.id }
}

output "worker_pool_names" {
  description = "Mapa {chave => name} dos Cloud Build private worker pools criados (usado por spoke-modelagem para apontar o trigger)."
  value       = { for key, pool in google_cloudbuild_worker_pool.this : key => pool.name }
}

output "worker_pool_states" {
  description = "Mapa {chave => state} dos Cloud Build private worker pools."
  value       = { for key, pool in google_cloudbuild_worker_pool.this : key => pool.state }
}

output "cloudbuild_sa_emails" {
  description = "Mapa {chave => email} das service accounts do Cloud Build (usar em `service_account` do trigger)."
  value       = { for key, sa in google_service_account.cloudbuild : key => sa.email }
}

output "cloudbuild_sa_ids" {
  description = "Mapa {chave => id} (resource id) das service accounts do Cloud Build."
  value       = { for key, sa in google_service_account.cloudbuild : key => sa.id }
}

output "cloudbuild_default_bucket_names" {
  description = "Mapa {project_id => name} dos buckets padrão do Cloud Build (<project_id>_cloudbuild), um por projeto entre os worker pools."
  value       = { for project_id, bucket in google_storage_bucket.cloudbuild_default : project_id => bucket.name }
}
