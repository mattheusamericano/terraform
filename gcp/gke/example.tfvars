# ============================================================
# Exemplo de uso - GKE Cluster + Nodepool
# ============================================================

# --- Módulo Cluster ---
gke_cluster_settings = {
  gke = {
    project_id             = "prj-risco-sigrm-prd"
    region                 = "southamerica-east1"
    sigla                  = "sigrm"
    network_project_id     = "prj-network-services-prd-cef"
    name_vpc_shared        = "vpc-negocio-prd"
    subnet_name            = "sub-risco-sigrm-prd"
    master_ipv4_cidr_block = "172.16.0.0/28"
    pods_range_name        = "pods-sigrm-prd"
    services_range_name    = "services-sigrm-prd"

    master_authorized_networks = [
      {
        name = "corp-network"
        cidr = "10.0.0.0/8"
      }
    ]

    kms_project_id   = "prj-hsm-services-prd"
    kms_keyring_name = "infraNPRDring"
    kms_key_name     = "infraNPRDSYMAES256hsm001"

    labels = {
      team = "platform"
      app  = "sigrm"
    }
  }
}

# --- Módulo Nodepool ---
gke_nodepool_settings = {
  # Nodepool de sistema - componentes do GKE
  system = {
    project_id   = "prj-risco-sigrm-prd"
    region       = "southamerica-east1"
    sigla        = "sigrm"
    cluster_name = "gke-sigrm-prd"       # output do módulo cluster
    gke_sa_email = "sa-gke-gke-sigrm-prd@prj-risco-sigrm-prd.iam.gserviceaccount.com"

    machine_type   = "e2-standard-4"
    disk_type      = "pd-ssd"
    disk_size_gb   = 100
    min_node_count = 1
    max_node_count = 3

    taints = [
      {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]

    labels = { role = "system" }
  }

  # Nodepool de aplicação
  app = {
    project_id   = "prj-risco-sigrm-prd"
    region       = "southamerica-east1"
    sigla        = "sigrm"
    cluster_name = "gke-sigrm-prd"
    gke_sa_email = "sa-gke-gke-sigrm-prd@prj-risco-sigrm-prd.iam.gserviceaccount.com"

    machine_type   = "e2-standard-8"
    disk_type      = "pd-ssd"
    disk_size_gb   = 100
    min_node_count = 2
    max_node_count = 10

    taints = []
    labels = { role = "app" }
  }
}
