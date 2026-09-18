resource "google_access_context_manager_service_perimeter_ingress_policy" "rule" {
  for_each = var.ingress_policies

  perimeter = local.perimeter
  title     = coalesce(each.value.title, each.key)

  ingress_from {
    identity_type = each.value.ingress_from.identity_type
    identities    = each.value.ingress_from.identities

    dynamic "sources" {
      for_each = each.value.ingress_from.sources
      content {
        access_level = sources.value.access_level
        resource     = sources.value.resource
      }
    }
  }

  ingress_to {
    resources = each.value.ingress_to.resources
    roles     = each.value.ingress_to.roles

    dynamic "operations" {
      for_each = each.value.ingress_to.operations
      content {
        service_name = operations.value.service_name

        dynamic "method_selectors" {
          for_each = operations.value.method_selectors
          content {
            method     = method_selectors.value.method
            permission = method_selectors.value.permission
          }
        }
      }
    }
  }
}
