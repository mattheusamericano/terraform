# Bucket padrão do Cloud Build (gs://<project_id>_cloudbuild) — nome fixo que
# o próprio Cloud Build usa por convenção como destino de staging do source
# (`gcloud builds submit`) quando nenhum --gcs-source-staging-dir/source
# customizado é informado. Provisionado aqui em vez de depender da criação
# implícita do Cloud Build na hora do primeiro build, que falha em projetos
# com Org Policy restringindo criação de bucket fora do Terraform.
resource "google_storage_bucket" "cloudbuild_default" {
  for_each = local.cloudbuild_default_buckets

  name                        = "${each.key}_cloudbuild"
  project                     = each.key
  location                    = each.value
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}
