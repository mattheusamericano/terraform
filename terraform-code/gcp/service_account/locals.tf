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
}
