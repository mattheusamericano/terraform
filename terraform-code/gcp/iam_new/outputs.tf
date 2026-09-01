output "custom_role_ids" {
  description = "Nomes completos (projects/{project}/roles/{role_id}) das custom roles criadas, indexados pela chave usada em custom_roles."
  value = {
    for k, v in google_project_iam_custom_role.this : k => v.name
  }
}

output "dataform_service_agent_member" {
  description = "Identidade do Dataform Service Agent (\"serviceAccount:service-<PROJECT_NUMBER>@gcp-sa-dataform.iam.gserviceaccount.com\") quando dataform_service_agent.enabled = true; null caso contrário. Útil se o stack precisar conceder mais alguma role a essa identidade fora deste módulo."
  value       = local.dataform_service_agent_member
}
