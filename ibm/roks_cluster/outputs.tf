output "cluster_ids" {
  description = "Mapa chave => ID do cluster ROKS. Usar como cluster_id no modulo roks_worker_pool."
  value       = { for k, v in ibm_container_vpc_cluster.this : k => v.id }
}

output "cluster_crns" {
  description = "Mapa chave => CRN do cluster ROKS."
  value       = { for k, v in ibm_container_vpc_cluster.this : k => v.crn }
}

output "ingress_hostnames" {
  description = "Mapa chave => hostname de ingress atribuido ao cluster."
  value       = { for k, v in ibm_container_vpc_cluster.this : k => v.ingress_hostname }
}

output "public_service_endpoint_urls" {
  description = "Mapa chave => URL publica do master (API), quando disable_public_service_endpoint = false."
  value       = { for k, v in ibm_container_vpc_cluster.this : k => v.public_service_endpoint_url }
}

output "private_service_endpoint_urls" {
  description = "Mapa chave => URL privada do master (API)."
  value       = { for k, v in ibm_container_vpc_cluster.this : k => v.private_service_endpoint_url }
}

output "cluster_states" {
  description = "Mapa chave => estado atual do cluster."
  value       = { for k, v in ibm_container_vpc_cluster.this : k => v.state }
}
