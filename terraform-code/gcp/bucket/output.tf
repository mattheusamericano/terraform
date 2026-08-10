output "bucket_names" {
    description     = "Nome de todos os buckets criados"
    value           = { for k, v in google_storage_bucket.bucket : k => v.name } 
}

output "bucket_urls" {
    description     = "URLs de todos os buckets criados"
    value           = { for k, v in google_storage_bucket.bucket : k => v.url}
}

output "bucket_self_links" {
    description     = "Self-Links dos buckets (Util para IAM)"
    value           = { for k, v in google_storage_bucket.bucket : k => v.self_link}
}

output "bucket_locations" {
    description     = "Região de cada bucket"
    value           = { for k, v in google_storage_bucket.bucket : k => v.location}
}