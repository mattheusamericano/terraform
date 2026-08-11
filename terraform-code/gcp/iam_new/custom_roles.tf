resource "google_project_iam_custom_role" "this" {
  for_each = var.custom_roles

  project     = var.project_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description != "" ? each.value.description : "[Terraform] ${each.value.title}"
  permissions = each.value.permissions
  stage       = each.value.stage
}

locals {
  # Resolve referências "custom:<chave>" para o nome real da role criada acima.
  custom_role_lookup = {
    for k, v in google_project_iam_custom_role.this : "custom:${k}" => v.name
  }
}
