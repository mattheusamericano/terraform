output "ingress_policy_ids" {
  description = "ID de cada regra de ingress criada, indexado pela mesma chave de var.ingress_policies."
  value = {
    for key, rule in google_access_context_manager_service_perimeter_ingress_policy.rule : key => rule.id
  }
}

output "ingress_policy_perimeters" {
  description = "Resource name completo do perímetro alvo de cada regra de ingress, indexado pela mesma chave de var.ingress_policies."
  value       = local.ingress_perimeters
}

output "egress_policy_ids" {
  description = "ID de cada regra de egress criada, indexado pela mesma chave de var.egress_policies."
  value = {
    for key, rule in google_access_context_manager_service_perimeter_egress_policy.rule : key => rule.id
  }
}

output "egress_policy_perimeters" {
  description = "Resource name completo do perímetro alvo de cada regra de egress, indexado pela mesma chave de var.egress_policies."
  value       = local.egress_perimeters
}
