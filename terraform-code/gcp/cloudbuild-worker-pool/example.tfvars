worker_pool_settings = {
  modelagem = {
    sigla      = "sipml"
    project_id = "prj-spoke-modelagem"
    location   = "southamerica-east1"

    network_project_id      = "prj-spoke-modelagem"
    network_name             = "vpc-spoke-modelagem"
    peered_network_ip_range = "192.168.0.0/29"

    machine_type   = "e2-standard-4"
    disk_size_gb   = 100
    no_external_ip = true

    # SA do GitHub Actions/Cloud Build de outro projeto que também deve poder usar o pool
    worker_pool_users = [
      "serviceAccount:sa-cloudbuild-gha@prj-sipml-gateway-prd.iam.gserviceaccount.com",
    ]

    annotations = {
      ambiente = "prd"
      squad    = "sudea"
    }
  }
}
