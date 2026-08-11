output "service_account_emails" {
  description = "E-mails das Service Accounts criadas, indexados pela chave usada em sa_settings."
  value = {
    for k, v in google_service_account.sa : k => v.email
  }
}

output "service_account_ids" {
  description = "IDs completos (projects/{project}/serviceAccounts/{email}) das Service Accounts criadas, indexados pela chave usada em sa_settings."
  value = {
    for k, v in google_service_account.sa : k => v.id
  }
}

output "custom_role_ids" {
  description = "Nomes completos (projects/{project}/roles/{role_id}) das custom roles criadas, indexados pela chave usada em custom_roles."
  value = {
    for k, v in google_project_iam_custom_role.this : k => v.name
  }
}
