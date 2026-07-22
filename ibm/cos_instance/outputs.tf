output "instance_crns" {
  description = "Mapa chave => CRN da instancia COS. Usar como instance_crn no modulo cos_bucket."
  value       = { for k, v in ibm_resource_instance.this : k => v.id }
}

output "instance_guids" {
  description = "Mapa chave => GUID da instancia COS. Usar como instance_guid no modulo cos_bucket (necessario para IAM em nivel de bucket)."
  value       = { for k, v in ibm_resource_instance.this : k => v.guid }
}

output "instance_names" {
  description = "Mapa chave => nome real da instancia COS criada."
  value       = { for k, v in ibm_resource_instance.this : k => v.name }
}
