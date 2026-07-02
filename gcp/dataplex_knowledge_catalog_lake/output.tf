output "ids" {
  description = "IDs dos lakes criados, indexados por lake_key"
  value = { for k, v in google_dataplex_lake.lake : k => v.id }
}

output "names" {
  description = "Nomes dos lakes criados, indexados por lake_key — usado pelos módulos dataplex-zone e dataplex-iam"
  value = { for k, v in google_dataplex_lake.lake : k => v.name }
}
