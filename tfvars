project_id = "prj-modelagem-gepld-prd"

region             = "southamerica-east1"
project_number     = "890964626578"
network_project_id = "prj-network-services-prd-cef"

kms_project_id = "prj-hsm-services-prd"
key_ring       = "infrahsmPRDring"
key_crypto     = "infraPRDSYMAES256hsm001"

### Configurations - Buckets
name_bucket_shared_log  = "bucket-log"
email                   = "sa-terraform@terraform-442218.iam.gserviceaccount.com"
org_id                  = "61181892930"
billing_id              = "0185E2-C40114-3FEE72"
string                  = "cef"
vpc_name                = "vpc-negocio-prd"
subnet_name             = "sub-risco-gepld-prd"
shared-project-log      = "prj-log-services-prd-cef"
shared-project-network  = "prj-network-services-prd-cef"
logging-custom-role-id  = "log_custom_role_cef"
sink_bucket_destination = "log-bucket"
bucket_id_shared_log    = "TODO"
name_logging_sink       = "sink"
log-retention-days      = "1825"
gcp_project_automate = {
  "prj-modelagem-gepld-prd" = {
    name       = "prj-modelagem-gepld-prd"
    project-id = "prj-modelagem-gepld-prd"
    folder-id  = "710378267372"
    area       = "modelagem"
    ambiente   = "prd"
    proposito  = "modelagem-gepld"
  }
}

gcp_editors = [
  "group:g_gcp_des_risco@corp.caixa.gov.br",
]

name_workbench            = "workbench-gepld"
workbench_machine_type    = "e2-standard-4"
workbench_disk_size_gb    = 100
workbench_disk_type       = "PD_BALANCED"
workbench_disk_encryption = "CMEK"
name_vpc_shared           = "vpc-negocio-prd"
name_subnet_vpc_shared    = "sub-risco-gepld-prd"
repository_python_name    = "acr-modelagem-gepld-prd-001"
workbench_members = [
  "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br",
  "group:G_GCP_RISCVALID_DTSC@corp.caixa.gov.br",
]

name_pv_worker_pool      = "pv-worker-pool-modelagem-gepld-prd"
disk_size_gb_worker_pool = 100
machine_type_worker_pool = "e2-medium"
no_external_ip           = true
peered_network_ip_range  = "/29"
name_trigger             = "trigger-modelagem-gepld-prd"
branch_name              = "main"
path                     = "cloudbuild.yaml"
uri                      = "https://github.com/TODO/TODO"
repo_name                = "TODO"
name_connection          = "TODO"

### Firewall Policy
fw-policy-name        = "fw-policy-actions"
fw-policy-description = "Firewall Policy for Actions VM"
dest_fqdns_allow      = []
ip_protocol_allow     = "tcp"
ports_allow           = ["80", "443", "8080"]


### Cloud Run

image_cloud_run       = "us-docker.pkg.dev/cloudrun/container/hello"
service_name_cloud_run = "run-app-gepld-prd"

### Secret
sm_app_id          = "GITHUB_APP_ID"
sm_installation_id = "GITHUB_INSTALLATION_ID"
sm_key_pem         = "GITHUB_KEY_PEM"
ml_data_scientist_permissions = [
  "aiplatform.notebookRuntimes.assign",
  "aiplatform.notebookRuntimes.delete",
  "aiplatform.notebookRuntimes.get",
  "aiplatform.notebookRuntimes.list",
  "aiplatform.notebookRuntimes.start",
  "aiplatform.notebookRuntimes.update",
  "aiplatform.notebookRuntimes.upgrade",
  "aiplatform.customJobs.create",
  "aiplatform.customJobs.cancel",
  "aiplatform.customJobs.get",
  "aiplatform.customJobs.list",
  "aiplatform.hyperparameterTuningJobs.create",
  "aiplatform.hyperparameterTuningJobs.cancel",
  "aiplatform.hyperparameterTuningJobs.get",
  "aiplatform.hyperparameterTuningJobs.list",
  "aiplatform.pipelineJobs.create",
  "aiplatform.pipelineJobs.cancel",
  "aiplatform.pipelineJobs.get",
  "aiplatform.pipelineJobs.list",
  "aiplatform.models.upload",
  "aiplatform.models.delete",
  "aiplatform.models.export",
  "aiplatform.models.get",
  "aiplatform.models.list",
  "aiplatform.models.update",
  "aiplatform.metadataStores.get",
  "aiplatform.metadataStores.list",
  "aiplatform.tensorboards.get",
  "aiplatform.tensorboards.list",
  "aiplatform.tensorboardExperiments.create",
  "aiplatform.tensorboardExperiments.list",
  "aiplatform.tensorboardRuns.create",
  "aiplatform.tensorboardRuns.list",
  "storage.objects.create",
  "storage.objects.delete",
  "storage.objects.get",
  "storage.objects.list",
  "storage.objects.update",
  "storage.buckets.get",
  "storage.buckets.list",
  "bigquery.jobs.create",
  "bigquery.datasets.get",
  "bigquery.tables.create",
  "bigquery.tables.get",
  "bigquery.tables.getData",
  "bigquery.tables.list",
  "logging.logEntries.list",
  "artifactregistry.repositories.get",
  "artifactregistry.repositories.list",
  "artifactregistry.dockerimages.get",
  "artifactregistry.dockerimages.list",
  "iam.serviceAccounts.actAs",
  "iam.serviceAccounts.get",
  "iam.serviceAccounts.list",
  "resourcemanager.projects.get",
  "dataform.repositories.create"
  
]
ml_engineer_permissions = [
  "iam.serviceAccounts.actAs",
  "artifactregistry.repositories.downloadArtifacts",
  "artifactregistry.repositories.uploadArtifacts",
  "artifactregistry.repositories.get",
  "artifactregistry.repositories.list",
  "artifactregistry.tags.create",
  "artifactregistry.tags.list",
  "artifactregistry.tags.update",
  "artifactregistry.versions.get",
  "artifactregistry.versions.list",
  "aiplatform.endpoints.create",
  "aiplatform.endpoints.delete",
  "aiplatform.endpoints.deploy",
  "aiplatform.endpoints.explain",
  "aiplatform.endpoints.get",
  "aiplatform.endpoints.getIamPolicy",
  "aiplatform.endpoints.list",
  "aiplatform.endpoints.predict",
  "aiplatform.endpoints.setIamPolicy",
  "aiplatform.endpoints.undeploy",
  "aiplatform.endpoints.update",
  "aiplatform.models.delete",
  "aiplatform.models.export",
  "aiplatform.models.get",
  "aiplatform.models.list",
  "aiplatform.models.update",
  "aiplatform.models.upload",
  "aiplatform.deploymentResourcePools.create",
  "aiplatform.deploymentResourcePools.delete",
  "aiplatform.deploymentResourcePools.get",
  "aiplatform.deploymentResourcePools.list",
  "aiplatform.deploymentResourcePools.update",
  "aiplatform.indexEndpoints.create",
  "aiplatform.indexEndpoints.deploy",
  "aiplatform.indexEndpoints.get",
  "aiplatform.indexEndpoints.list",
  "aiplatform.indexEndpoints.undeploy",
  "aiplatform.indexEndpoints.update",
  "notebooks.instances.create",
  "notebooks.instances.delete",
  "notebooks.instances.get",
  "notebooks.instances.list",
  "notebooks.instances.update",
  "notebooks.instances.start",
  "aiplatform.notebookRuntimes.assign",
  "aiplatform.notebookRuntimes.delete",
  "aiplatform.notebookRuntimes.get",
  "aiplatform.notebookRuntimes.list",
  "aiplatform.notebookRuntimes.start",
  "aiplatform.notebookRuntimes.update",
  "aiplatform.notebookRuntimes.upgrade",
  "aiplatform.notebookExecutionJobs.create",
  "aiplatform.notebookExecutionJobs.delete",
  "aiplatform.notebookExecutionJobs.get",
  "aiplatform.notebookExecutionJobs.list",
  "aiplatform.pipelineJobs.cancel",
  "aiplatform.pipelineJobs.create",
  "aiplatform.pipelineJobs.delete",
  "aiplatform.pipelineJobs.get",
  "aiplatform.pipelineJobs.list",
  "aiplatform.trainingPipelines.cancel",
  "aiplatform.trainingPipelines.create",
  "aiplatform.trainingPipelines.delete",
  "aiplatform.trainingPipelines.get",
  "aiplatform.trainingPipelines.list",
  "aiplatform.customJobs.cancel",
  "aiplatform.customJobs.create",
  "aiplatform.customJobs.delete",
  "aiplatform.customJobs.get",
  "aiplatform.customJobs.list",
  "aiplatform.schedules.create",
  "aiplatform.schedules.delete",
  "aiplatform.schedules.get",
  "aiplatform.schedules.list",
  "aiplatform.schedules.update",
  "aiplatform.hyperparameterTuningJobs.create",
  "aiplatform.hyperparameterTuningJobs.get",
  "aiplatform.hyperparameterTuningJobs.list",
  "aiplatform.batchPredictionJobs.create",
  "aiplatform.batchPredictionJobs.get",
  "aiplatform.batchPredictionJobs.list",
  "aiplatform.metadataStores.create",
  "aiplatform.metadataStores.get",
  "aiplatform.metadataStores.list",
  "aiplatform.artifacts.create",
  "aiplatform.artifacts.get",
  "aiplatform.artifacts.list",
  "aiplatform.contexts.create",
  "aiplatform.contexts.get",
  "aiplatform.contexts.list",
  "aiplatform.executions.create",
  "aiplatform.executions.get",
  "aiplatform.executions.list",
  "aiplatform.modelEvaluations.get",
  "aiplatform.modelEvaluations.import",
  "aiplatform.modelEvaluations.list",
  "aiplatform.modelDeploymentMonitoringJobs.create",
  "aiplatform.modelDeploymentMonitoringJobs.delete",
  "aiplatform.modelDeploymentMonitoringJobs.get",
  "aiplatform.modelDeploymentMonitoringJobs.list",
  "aiplatform.modelDeploymentMonitoringJobs.update",
  "aiplatform.modelMonitors.create",
  "aiplatform.modelMonitors.get",
  "aiplatform.modelMonitors.list",
  "logging.logEntries.list",
  "monitoring.timeSeries.list",
  "monitoring.dashboards.create",
  "monitoring.dashboards.get",
  "monitoring.dashboards.list",
  "monitoring.dashboards.update",
  "storage.objects.create",
  "storage.objects.get",
  "storage.objects.list",
  "storage.objects.update",
  "bigquery.datasets.get",
  "bigquery.datasets.listEffectiveTags",
  "bigquery.tables.create",
  "bigquery.tables.get",
  "bigquery.tables.getData",
  "bigquery.tables.list",
  "bigquery.tables.update",
  "bigquery.tables.updateData",
  "aiplatform.featureGroups.get",
  "aiplatform.featureGroups.list",
  "aiplatform.featureGroups.update",
  "aiplatform.featureOnlineStores.get",
  "aiplatform.featureOnlineStores.list",
  "aiplatform.features.get",
  "aiplatform.features.list",
  "aiplatform.featurestores.get",
  "aiplatform.featurestores.list",
  "aiplatform.featurestores.writeFeatures",
  "aiplatform.featureViews.get",
  "aiplatform.featureViews.list",
  "aiplatform.featureViews.sync",
  "compute.machineTypes.list",
  "compute.regions.list",
  "compute.networks.list",
  "run.services.create",
  "run.services.delete",
  "run.services.get",
  "run.services.list",
  "run.services.update",
  "run.jobs.create",
  "run.jobs.run",
  "run.jobs.list",
  "run.executions.list",
  "container.clusters.get",
  "container.clusters.list",
  "container.pods.get",
  "container.pods.getLogs",
  "container.pods.list" 
]
data_engineer_permissions = [
  "compute.subnetworks.get",
  "compute.subnetworks.getIamPolicy",
  "compute.subnetworks.list",
  "iam.serviceAccounts.list",
  "bigquery.datasets.create",
  "bigquery.datasets.get",
  "bigquery.datasets.update",
  "bigquery.tables.create",
  "bigquery.tables.delete",
  "bigquery.tables.get",
  "bigquery.tables.getData",
  "bigquery.tables.list",
  "bigquery.tables.update",
  "bigquery.tables.updateData",
  "bigquery.jobs.create",
  "bigquery.jobs.list",
  "bigquery.readsessions.create",
  "storage.buckets.create",
  "storage.buckets.get",
  "storage.buckets.list",
  "storage.buckets.update",
  "storage.objects.create",
  "storage.objects.delete",
  "storage.objects.get",
  "storage.objects.list",
  "storage.objects.update",
  "dataflow.jobs.create",
  "dataflow.jobs.cancel",
  "dataflow.jobs.get",
  "dataflow.jobs.list",
  "dataflow.jobs.updateContents",
  "dataflow.metrics.get",
  "composer.environments.get",
  "composer.environments.list",
  "composer.environments.update",
  "composer.dags.execute",
  "composer.dags.get",
  "composer.dags.list",
  "composer.dags.getSourceCode",
  "pubsub.topics.create",
  "pubsub.topics.get",
  "pubsub.topics.list",
  "pubsub.topics.publish",
  "pubsub.subscriptions.create",
  "pubsub.subscriptions.consume",
  "artifactregistry.repositories.get",
  "artifactregistry.repositories.list",
  "artifactregistry.repositories.downloadArtifacts",
  "artifactregistry.repositories.uploadArtifacts",
  "compute.machineTypes.list",
  "compute.regions.list",
  "compute.networks.list",
  "run.services.create",
  "run.services.get",
  "run.services.update",
  "run.jobs.create",
  "run.jobs.run",
  "run.executions.list",
  "logging.logEntries.list",
  "monitoring.timeSeries.list",
  "monitoring.dashboards.create",
  "monitoring.dashboards.get",
   "monitoring.dashboards.update",
  "errorreporting.groups.list"
]

services_apis_list = [
    "aiplatform.googleapis.com",
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
    "composer.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerfilesystem.googleapis.com",
    "containerregistry.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "datalineage.googleapis.com",
    "dataplex.googleapis.com",
    "deploymentmanager.googleapis.com",
    "developerconnect.googleapis.com",
    "dns.googleapis.com",
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
    "storagetransfer.googleapis.com",
    "datastream.googleapis.com",
    "dataproc.googleapis.com",
    "datafusion.googleapis.com",
    "cloudscheduler.googleapis.com",
    "workflows.googleapis.com",
    "eventarc.googleapis.com",
    "alloydb.googleapis.com",
    "sqladmin.googleapis.com",
    "firestore.googleapis.com",
    "bigtable.googleapis.com",
    "integrations.googleapis.com",
    "documentai.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "iap.googleapis.com",
    "connectors.googleapis.com"
  ]


