output "service_account_emails" {
  description = "E-mail de cada Service Account criada"
  value = {
    for k, v in google_service_account.sa : k => v.email
  }
}

output "service_account_names" {
  description = "Nome completo (resource name) de cada Service Account criada"
  value = {
    for k, v in google_service_account.sa : k => v.name
  }
}

output "service_account_account_ids" {
  description = "account_id (parte local do e-mail, antes do @) de cada Service Account criada"
  value = {
    for k, v in google_service_account.sa : k => v.account_id
  }
}

output "service_account_unique_ids" {
  description = "unique_id (identificador numérico estável do IAM) de cada Service Account criada"
  value = {
    for k, v in google_service_account.sa : k => v.unique_id
  }
}