output "feature_store_ids" { value = { for k,v in google_ai_platform_featurestore.featurestore : k => v.id } }
