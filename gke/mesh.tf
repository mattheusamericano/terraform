# ============================================================
# Cloud Service Mesh (Istio gerenciado pelo Google)
# ============================================================

# Fleet membership - registra o cluster na fleet do projeto
resource "google_gke_hub_membership" "membership" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.enable_service_mesh
  }

  membership_id = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  project       = each.value.project_id

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.cluster[each.key].id}"
    }
  }

  depends_on = [google_container_cluster.cluster]
}

# Habilita o feature de Service Mesh na fleet
resource "google_gke_hub_feature" "servicemesh" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.enable_service_mesh
  }

  name     = "servicemesh"
  location = "global"
  project  = each.value.project_id

  depends_on = [google_gke_hub_membership.membership]
}

# Configura o Service Mesh no membership
resource "google_gke_hub_feature_membership" "servicemesh_config" {
  for_each = {
    for k, v in var.gke_cluster_settings : k => v
    if v.enable_service_mesh
  }

  location   = "global"
  feature    = "servicemesh"
  membership = google_gke_hub_membership.membership[each.key].membership_id
  project    = each.value.project_id

  mesh {
    # MANAGEMENT_AUTOMATIC = Google gerencia o Istio automaticamente
    management = "MANAGEMENT_AUTOMATIC"
  }

  depends_on = [google_gke_hub_feature.servicemesh]
}
