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
}
