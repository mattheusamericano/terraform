# ============================================================
# Agent Builder - Endpoint
# ============================================================

resource "google_vertex_ai_endpoint" "endpoint" {
  for_each = var.agent_builder_endpoint_settings

  project  = each.value.project_id
  location = each.value.region

  name         = each.value.endpoint_name
  display_name = each.value.display_name
  description  = each.value.description

  labels = each.value.labels

  dedicated_endpoint_enabled = each.value.dedicated_endpoint_enabled

 
}
