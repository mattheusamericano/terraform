output "service_account_emails" {
  description = "E-mails das Service Accounts criadas pelo módulo iam, indexados pela chave usada em sa_settings."
  value       = module.iam.service_account_emails
}

output "custom_role_ids" {
  description = "Nomes completos das custom roles criadas pelo módulo iam."
  value       = module.iam.custom_role_ids
}
