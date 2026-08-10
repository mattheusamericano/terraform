locals {
  common_labels = {
      "ambiente"                               = "__environment__"
      "equipeinfra"                            = "cesti35"
      "equipesolucao"                          = "__sigla__"
      "solucao"                                = "__sigla__"
      "provimento"                             = "terraform"
      "workload"                               = "__sigla__"
    }

  apis_list = [
    "aiplatform.googleapis.com",
    "dataproc.googleapis.com",
    "analyticshub.googleapis.com",
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "biglake.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerfilesystem.googleapis.com",
    "containerregistry.googleapis.com",
    "composer.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
    "deploymentmanager.googleapis.com",
    "developerconnect.googleapis.com",
    "dns.googleapis.com",
    "firestore.googleapis.com",
    "gkehub.googleapis.com",
    "generativelanguage.googleapis.com",
    "gkebackup.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "integrations.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "networkconnectivity.googleapis.com",
    "notebooks.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "visionai.googleapis.com",
    "websecurityscanner.googleapis.com",
    "integrations.googleapis.com",
    "documentai.googleapis.com",
    "eventarc.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com"
  ]
}