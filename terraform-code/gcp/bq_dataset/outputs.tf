output "dataset_ids" {
  description = "ID dos datasets criados"
  value = {
    for k, v in google_bigquery_dataset.dataset :
    k => v.dataset_id
  }
}

output "dataset_self_links" {
  description = "Self links dos datasets"
  value = {
    for k, v in google_bigquery_dataset.dataset :
    k => v.self_link
  }
}

output "dataset_project_ids" {
  description = "Projetos dos datasets"
  value = {
    for k, v in google_bigquery_dataset.dataset :
    k => v.project
  }
}

output "dataset_sa_emails" {
  description = "Emails das SAs de cada dataset"
  value = {
    for k, v in google_service_account.bq_dataset_sa : k => v.email
  }
}