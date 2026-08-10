output "ids" {
  description = "IDs das zones criadas, indexados pela chave do mapa"
  value = { for k, v in google_dataplex_zone.zone : k => v.id }
}

output "names" {
  description = "Nomes das zones criadas, indexados pela chave do mapa — usado pelo módulo dataplex-asset"
  value = { for k, v in google_dataplex_zone.zone : k => v.name }
}
