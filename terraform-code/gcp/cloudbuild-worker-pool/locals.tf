# Flatten multi-nível (pool -> lista de worker_pool_users) para viabilizar o
# for_each do IAM aditivo em iam.tf.
locals {
  worker_pool_user_bindings = {
    for pair in flatten([
      for key, settings in var.worker_pool_settings : [
        for user in settings.worker_pool_users : {
          id     = "${key}-${user}"
          key    = key
          member = user
        }
      ]
    ]) : pair.id => pair
  }

  # Flatten multi-nível (pool -> lista de roles em service_account.roles) para
  # viabilizar o for_each do IAM aditivo da SA do Cloud Build em iam.tf. Mesmo mapa
  # de origem (var.worker_pool_settings) usado por main.tf e sa.tf.
  cloudbuild_sa_role_bindings = {
    for pair in flatten([
      for key, settings in var.worker_pool_settings : [
        for role in settings.service_account.roles : {
          id      = "${key}-${role}"
          key     = key
          project = settings.project_id
          role    = role
        }
      ]
    ]) : pair.id => pair
  }

  # O bucket padrão do Cloud Build (gs://<project_id>_cloudbuild, usado por
  # `gcloud builds submit` para staging do source quando --gcs-source-staging-dir
  # não é informado) é por PROJETO, não por pool — um projeto pode ter mais de
  # um worker pool (chaves diferentes de worker_pool_settings com o mesmo
  # project_id). Dedup por project_id evita duas entradas tentando gerenciar o
  # mesmo bucket em paralelo (mesmo nome, resource address diferente ->
  # conflito no plan/apply). A location usada é a do primeiro pool encontrado
  # para aquele projeto.
  cloudbuild_default_buckets = {
    for project_id in distinct([for settings in var.worker_pool_settings : settings.project_id]) :
    project_id => [
      for settings in var.worker_pool_settings : settings.location
      if settings.project_id == project_id
    ][0]
  }
}
