output "identity_pool_ids" {
  description = "IDs dos workload identity pools criados"
  value = {
    for k, v in google_iam_workload_identity_pool.identity_pool :
    k => v.workload_identity_pool_id
  }
}

output "identity_pool_names" {
  description = "Resource names completos dos pools"
  value = {
    for k, v in google_iam_workload_identity_pool.identity_pool :
    k => v.name
  }
}

output "provider_names" {
  description = "Resource names dos providers (útil para WIF binding)"
  value = {
    for k, v in google_iam_workload_identity_pool_provider.identity_pool_provider :
    k => v.name
  }
}

output "sa_binding_etags" {
  description = "ETags dos IAM bindings (útil para auditoria)"
  value = {
    for k, v in google_service_account_iam_binding.wipool_identity_binding :
    k => v.etag
  }
}