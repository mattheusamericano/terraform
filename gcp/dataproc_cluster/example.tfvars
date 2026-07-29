# Reproduz o comando gcloud atualmente usado para o cluster dp-01-pub-des

cluster_settings = {
  "01" = {
    sigla      = "pub"
    project_id = "prj-publisher-poc"
    region     = "southamerica-east1"

    subnetwork       = "projects/prj-network-services-des-cef/regions/southamerica-east1/subnetworks/sub-poc-des"
    internal_ip_only = true # --no-address

    service_account         = "sa-wb-01-pub-des@prj-publisher-poc.iam.gserviceaccount.com"
    service_account_scopes  = ["https://www.googleapis.com/auth/cloud-platform"]

    master_settings = {
      machine_type      = "n4-standard-2"
      boot_disk_type     = "hyperdisk-balanced"
      boot_disk_size_gb  = 100
      num_instances      = 1
    }

    worker_settings = {
      machine_type      = "n4-standard-2"
      boot_disk_type     = "hyperdisk-balanced"
      boot_disk_size_gb  = 200
      num_instances      = 2
    }

    image_version            = "2.3-debian12"
    optional_components      = ["JUPYTER"]
    enable_component_gateway = true

    override_properties = {
      # no comando gcloud original essa chave é passada sem valor explícito;
      # confirme com a doc do Lightning Engine se "" é o esperado ou se deve ser "true"
      "spark:spark.dataproc.engine.lightningEngine" = ""
      "spark:spark.dataproc.lightningEngine.runtime" = "native"
    }

    autoscaling_policy_uri = "projects/prj-publisher-poc/locations/southamerica-east1/autoscalingPolicies/autoscale-policy"

    # VPC compartilhada com prj-network-services-des-cef
    shared_vpc_host_project = "prj-network-services-des-cef"

    # roles/dataproc.worker para a SA do hub em terraform-442218
    additional_project_bindings = {
      hub-worker = {
        project_id = "terraform-442218"
        role       = "roles/dataproc.worker"
        member     = "serviceAccount:sa-wb-01-hub-des@terraform-442218.iam.gserviceaccount.com"
      }
    }
  }
}
