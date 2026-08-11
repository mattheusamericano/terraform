output "custom_role_ids" {
  description = "Nomes completos (projects/{project}/roles/{role_id}) das custom roles criadas, indexados pela chave usada em custom_roles."
  value = {
    for k, v in google_project_iam_custom_role.this : k => v.name
  }
}
