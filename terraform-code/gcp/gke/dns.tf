resource "google_dns_managed_zone" "interna" {
    for_each = var.gke_cluster_settings

    name            = "dns-internal-gke-${each.value.sigla}-${terraform.workspace}"
    dns_name        = "${each.value.sigla}.caixa.gov.br."
    description     = "Zona Interna gerenciada pelo External DNS"
    project         = each.value["project_id"]
    visibility      = "private"

    private_visibility_config {
        networks {
            network_url = data.google_compute_network.vpc[each.key].self_link
        }
    }
}



resource "google_service_account" "external_dns_service" {
    for_each = var.gke_cluster_settings

    account_id      = "sa-external-dns-${each.value.sigla}"
    display_name    = "External DNS SA"
    project         = each.value["project_id"]
}

resource "google_project_iam_member" "external_dns_sa" {
    for_each = var.gke_cluster_settings

    project         = each.value["project_id"]
    role            = "roles/dns.admin"
    member          = "serviceAccount:${google_service_account.external_dns_service[each.key].email}"

}

resource "google_service_account_iam_member" "external_dns_wi" {
    for_each = var.gke_cluster_settings

    service_account_id      = google_service_account.external_dns_service[each.key].name
    role                    = "roles/iam.workloadIdentityUser"
    member                  = "serviceAccount:${each.value.project_id}.svc.id.goog[external-dns/external-dns]"

}