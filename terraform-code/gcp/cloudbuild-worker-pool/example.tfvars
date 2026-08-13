worker_pool_settings = {
  modelagem = {
    sigla      = "sipml"
    project_id = "prj-spoke-modelagem"
    location   = "southamerica-east1"

    network_project_id = "prj-spoke-modelagem"
    network_name        = "vpc-spoke-modelagem"
    # já existe range reservado (Private Services Access) anexado a essa VPC;
    # deixamos null para o Cloud Build alocar automaticamente um /29 dentro dele
    peered_network_ip_range = null

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

    # SA dedicada deste pool, criada e permissionada junto no mesmo for_each
    service_account = {
      display_name = "SA Cloud Build - pipeline modelagem SIPML"

      # lista completa e customizável por projeto/pipeline
      roles = [
        "roles/bigquery.jobUser",
        "roles/bigquery.user",
        "roles/storage.objectAdmin",
        "roles/artifactregistry.writer",
      ]
    }
  }
}
