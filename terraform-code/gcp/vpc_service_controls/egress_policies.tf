resource "google_access_context_manager_service_perimeter_egress_policy" "rule" {
  for_each = var.egress_policies

  perimeter = local.egress_perimeters[each.key]
  title     = coalesce(each.value.title, each.key)

  egress_from {
    identity_type      = each.value.egress_from.identity_type
    identities         = each.value.egress_from.identities
    source_restriction = each.value.egress_from.source_restriction

    dynamic "sources" {
      for_each = each.value.egress_from.sources
      content {
        access_level = sources.value.access_level
        resource     = sources.value.resource
      }
    }
  }

  egress_to {
    resources          = each.value.egress_to.resources
    external_resources = each.value.egress_to.external_resources
    roles              = each.value.egress_to.roles

    dynamic "operations" {
      for_each = each.value.egress_to.operations
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
