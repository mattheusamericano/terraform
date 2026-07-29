output "session_template_names" {
  description = "Nome completo (resource name) de cada session template, por chave do mapa de entrada."
  value       = { for k, v in google_dataproc_session_template.this : k => v.name }
}

output "session_template_ids" {
  description = "ID de cada session template criado, por chave do mapa de entrada."
  value       = { for k, v in google_dataproc_session_template.this : k => v.id }
}

output "session_template_uuids" {
  description = "UUID gerado pelo serviço para cada session template."
  value       = { for k, v in google_dataproc_session_template.this : k => v.uuid }
}
