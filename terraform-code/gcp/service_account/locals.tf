# Flatten multi-nível (SA -> lista de roles em sa_settings.*.roles) para viabilizar
# o for_each do IAM aditivo em iam.tf. Cada SA do mapa pode ter uma lista de roles
# diferente das demais.
locals {
  sa_role_bindings = {
    for pair in flatten([
      for key, settings in var.sa_settings : [
        for role in settings.roles : {
          id         = "${key}-${role}"
          key        = key
          project_id = settings.project_id
          role       = role
        }
      ]
    ]) : pair.id => pair
  }

  # Mesmo flatten, mas para sa_settings.*.cross_project_roles (project_id vem de
  # cada entrada da lista, não de settings.project_id) — viabiliza o for_each do
  # IAM cross-project em iam.tf.
  sa_cross_project_role_bindings = {
    for pair in flatten([
      for key, settings in var.sa_settings : [
        for cp in settings.cross_project_roles : {
          id         = "${key}-${cp.project_id}-${cp.role}"
          key        = key
          project_id = cp.project_id
          role       = cp.role
        }
      ]
    ]) : pair.id => pair
  }
}
