output "worker_pool_ids" {
  description = "Mapa chave => ID do worker pool criado."
  value       = { for k, v in ibm_container_vpc_worker_pool.this : k => v.id }
}
