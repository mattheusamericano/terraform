# ============================================================
# Outputs - GKE Nodepool Module
# ============================================================

output "nodepool_names" {
  description = "Nomes dos nodepools criados"
  value       = { for k, v in google_container_node_pool.nodepool : k => v.name }
}

output "nodepool_instance_group_urls" {
  description = "URLs dos instance groups dos nodepools"
  value       = { for k, v in google_container_node_pool.nodepool : k => v.managed_instance_group_urls }
}
