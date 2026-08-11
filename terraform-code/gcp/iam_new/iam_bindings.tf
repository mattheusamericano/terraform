locals {
  iam_bindings_additive      = { for k, v in var.iam_bindings : k => v if !v.authoritative }
  iam_bindings_authoritative = { for k, v in var.iam_bindings : k => v if v.authoritative }

  # "achata" cada entrada aditiva (role -> N membros) em um par (chave-membro) -> {role, member},
  # para que cada membro vire um google_project_iam_member independente e aditivo.
  iam_bindings_additive_pairs = {
    for pair in flatten([
      for k, v in local.iam_bindings_additive : [
        for m in v.members : {
          key    = "${k}-${m}"
          role   = v.role
          member = m
        }
      ]
    ]) : pair.key => pair
  }
}

# Aditivo (padrão e seguro): não remove outros membros já existentes na role.
resource "google_project_iam_member" "additive" {
  for_each = local.iam_bindings_additive_pairs

  project = var.project_id
  role    = startswith(each.value.role, "custom:") ? local.custom_role_lookup[each.value.role] : each.value.role
  member  = each.value.member
}

# Autoritativo (opt-in explícito via authoritative = true): substitui TODOS os membros da role.
resource "google_project_iam_binding" "authoritative" {
  for_each = local.iam_bindings_authoritative

  project = var.project_id
  role    = startswith(each.value.role, "custom:") ? local.custom_role_lookup[each.value.role] : each.value.role
  members = each.value.members
}
