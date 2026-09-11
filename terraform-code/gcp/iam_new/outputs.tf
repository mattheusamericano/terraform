output "project_id" {
  description = "Projeto GCP alvo deste módulo (repassa var.project_id)."
  value       = var.project_id
}

output "dataform_service_agent_member" {
  description = "Identidade do Dataform Service Agent (\"serviceAccount:service-<PROJECT_NUMBER>@gcp-sa-dataform.iam.gserviceaccount.com\") quando dataform_service_agent.enabled = true; null caso contrário. Útil se o stack precisar conceder mais alguma role a essa identidade fora deste módulo."
  value       = local.dataform_service_agent_member
}

output "ml_ops_profile_roles" {
  description = "Roles predefinidas concedidas a cada perfil ML Ops (ml_engineer, ml_data_scientist, data_engineer) na trilha de var.ml_ops_profiles.environment_type. null quando ml_ops_profiles.enabled = false."
  value = var.ml_ops_profiles.enabled ? {
    ml_engineer       = local.ml_engineer_roles
    ml_data_scientist = local.ml_data_scientist_roles
    data_engineer     = local.data_engineer_roles
  } : null
}

output "ml_ops_group_role_bindings" {
  description = "Todos os bindings perfil+role efetivamente criados pelos perfis ML Ops (chave -> {role, member}). {} quando ml_ops_profiles.enabled = false."
  value       = local.ml_ops_group_role_bindings
}
