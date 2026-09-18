output "perimeter" {
  description = "Resource name completo do perímetro alvo (accessPolicies/<access_policy_id>/servicePerimeters/<perimeter_name>), repassado para conveniência de quem consome o módulo."
  value       = local.perimeter
}

output "ingress_policy_ids" {
  description = "ID de cada regra de ingress criada, indexado pela mesma chave de var.ingress_policies."
  value = {
    for key, rule in google_access_context_manager_service_perimeter_ingress_policy.rule : key => rule.id
  }
}

output "egress_policy_ids" {
  description = "ID de cada regra de egress criada, indexado pela mesma chave de var.egress_policies."
  value = {
    for key, rule in google_access_context_manager_service_perimeter_egress_policy.rule : key => rule.id
  }
}
