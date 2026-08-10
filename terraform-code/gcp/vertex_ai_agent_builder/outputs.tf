output "ids" {
  description = "IDs dos Endpoints criados, indexados pela chave do mapa"

  value = {
    for k, v in google_vertex_ai_endpoint.endpoint :
    k => v.id
  }
}

output "names" {
  description = "Nomes dos Endpoints criados, indexados pela chave do mapa"

  value = {
    for k, v in google_vertex_ai_endpoint.endpoint :
    k => v.name
  }
}