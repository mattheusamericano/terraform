output "ids" {
  description = "IDs dos assets criados, indexados pela chave do mapa"
  value = { for k, v in google_dataplex_asset.asset : k => v.id }
}

output "names" {
  description = "Nomes dos assets criados"
  value = { for k, v in google_dataplex_asset.asset : k => v.name }
}
