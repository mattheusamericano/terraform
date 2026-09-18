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

  cloudbuild_first_pool_settings_by_project = {
    for project_id in distinct([for settings in var.worker_pool_settings : settings.project_id]) :
    project_id => [
      for settings in var.worker_pool_settings : settings
      if settings.project_id == project_id
    ][0]
  }

  cloudbuild_default_buckets = {
    for project_id, settings in local.cloudbuild_first_pool_settings_by_project :
    project_id => {
      location = settings.location
      kms_key_name = (
        settings.kms_key_ring != null
        ? "projects/${settings.kms_project_id}/locations/${settings.location}/keyRings/${settings.kms_key_ring}/cryptoKeys/${settings.kms_crypto_key}"
        : null
      )
    }
  }
}
