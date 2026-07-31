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
