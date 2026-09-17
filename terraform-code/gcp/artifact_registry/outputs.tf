output "artifact_registry_repositories" {
  description = "Repositórios Artifact Registry criados, indexados pela mesma chave de var.artifact_registry_settings."
  value = {
    for key, repo in google_artifact_registry_repository.artifact_registry : key => {
      id            = repo.id
      name          = repo.name
      repository_id = repo.repository_id
      location      = repo.location
      project       = repo.project
      format        = repo.format
      mode          = repo.mode
      kms_key_name  = repo.kms_key_name
    }
  }
}
