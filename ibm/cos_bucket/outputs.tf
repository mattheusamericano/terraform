output "bucket_ids" {
  description = "Mapa chave => ID do bucket criado."
  value       = { for k, v in ibm_cos_bucket.this : k => v.id }
}

output "bucket_crns" {
  description = "Mapa chave => CRN do bucket criado."
  value       = { for k, v in ibm_cos_bucket.this : k => v.crn }
}

output "bucket_names" {
  description = "Mapa chave => nome real do bucket criado."
  value       = { for k, v in ibm_cos_bucket.this : k => v.bucket_name }
}

output "s3_endpoints_public" {
  description = "Mapa chave => endpoint S3 publico do bucket."
  value       = { for k, v in ibm_cos_bucket.this : k => v.s3_endpoint_public }
}

output "s3_endpoints_private" {
  description = "Mapa chave => endpoint S3 privado do bucket."
  value       = { for k, v in ibm_cos_bucket.this : k => v.s3_endpoint_private }
}
