locals {
  iam_bindings_additive      = { for k, v in var.iam_bindings : k => v if !v.authoritative }
  iam_bindings_authoritative = { for k, v in var.iam_bindings : k => v if v.authoritative }

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

resource "google_project_iam_member" "additive" {
  for_each = local.iam_bindings_additive_pairs

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}

resource "google_project_iam_binding" "authoritative" {
  for_each = local.iam_bindings_authoritative

  project = var.project_id
  role    = each.value.role
  members = each.value.members
}
