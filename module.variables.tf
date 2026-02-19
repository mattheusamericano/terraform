variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}
variable "repository_python_name" {
  type = string
}

variable "workbench_members" {
  type    = list(string)
  default = []
}

variable "region" { type = string }

variable "key_ring" {
  type = string
}

variable "key_crypto" {
  type = string
}

variable "kms_project_id" { type = string }

variable "name_subnet_vpc_shared" {
  type = string
}

variable "network_project_id" {
  type = string
}

variable "sm_app_id" {
  type = string
}

variable "sm_installation_id" {
  type = string
}

variable "sm_key_pem" {
  type = string
}

variable "gcp_project_automate" {
  type = map(object({
    name       = string
    project-id = string
    folder-id  = string
    area       = string
    ambiente   = string
    proposito  = string
  }))
  default = {}
}

variable "bigquery_dataform_permissions" {
  type        = set(string)
  description = "[Terraform] - Basic permissions for Dataform User Service Account"
  default = [
    "bigquery.config.get",
    "bigquery.datasets.create",
    "bigquery.datasets.get",
    "bigquery.datasets.getIamPolicy",
    "bigquery.datasets.updateTag",
    "bigquery.jobs.create",
    "bigquery.models.create",
    "bigquery.models.delete",
    "bigquery.models.export",
    "bigquery.models.getData",
    "bigquery.models.getMetadata",
    "bigquery.models.list",
    "bigquery.models.updateData",
    "bigquery.models.updateMetadata",
    "bigquery.models.updateTag",
    "bigquery.routines.create",
    "bigquery.routines.delete",
    "bigquery.routines.get",
    "bigquery.routines.list",
    "bigquery.routines.update",
    "bigquery.routines.updateTag",
    "bigquery.tables.create",
    "bigquery.tables.createIndex",
    "bigquery.tables.createSnapshot",
    "bigquery.tables.delete",
    "bigquery.tables.deleteIndex",
    "bigquery.tables.export",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.tables.getIamPolicy",
    "bigquery.tables.list",
    "bigquery.tables.replicateData",
    "bigquery.tables.restoreSnapshot",
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "bigquery.tables.updateIndex",
    "bigquery.tables.updateTag",
    "cloudkms.keyHandles.create",
    "cloudkms.keyHandles.get",
    "cloudkms.keyHandles.list",
    "cloudkms.operations.get",
    "cloudkms.projects.showEffectiveAutokeyConfig",
    "dataform.commentThreads.get",
    "dataform.commentThreads.list",
    "dataform.comments.get",
    "dataform.comments.list",
    "dataform.compilationResults.create",
    "dataform.compilationResults.get",
    "dataform.compilationResults.list",
    "dataform.compilationResults.query",
    "dataform.config.get",
    "dataform.locations.get",
    "dataform.locations.list",
    "dataform.releaseConfigs.get",
    "dataform.releaseConfigs.list",
    "dataform.repositories.computeAccessTokenStatus",
    "dataform.repositories.create",
    "dataform.repositories.fetchHistory",
    "dataform.repositories.fetchRemoteBranches",
    "dataform.repositories.get",
    "dataform.repositories.getIamPolicy",
    "dataform.repositories.list",
    "dataform.repositories.queryDirectoryContents",
    "dataform.repositories.readFile",
    "dataform.workflowConfigs.get",
    "dataform.workflowConfigs.list",
    "dataform.workflowInvocations.cancel",
    "dataform.workflowInvocations.create",
    "dataform.workflowInvocations.delete",
    "dataform.workflowInvocations.get",
    "dataform.workflowInvocations.list",
    "dataform.workflowInvocations.query",
    "dataform.workspaces.commit",
    "dataform.workspaces.create",
    "dataform.workspaces.delete",
    "dataform.workspaces.fetchFileDiff",
    "dataform.workspaces.fetchFileGitStatuses",
    "dataform.workspaces.fetchGitAheadBehind",
    "dataform.workspaces.get",
    "dataform.workspaces.getIamPolicy",
    "dataform.workspaces.installNpmPackages",
    "dataform.workspaces.list",
    "dataform.workspaces.makeDirectory",
    "dataform.workspaces.moveDirectory",
    "dataform.workspaces.moveFile",
    "dataform.workspaces.pull",
    "dataform.workspaces.push",
    "dataform.workspaces.queryDirectoryContents",
    "dataform.workspaces.readFile",
    "dataform.workspaces.removeDirectory",
    "dataform.workspaces.removeFile",
    "dataform.workspaces.reset",
    "dataform.workspaces.searchFiles",
    "dataform.workspaces.writeFile"
  ]
}

variable "ml_viewer_permissions" {
  type        = set(string)
  description = "[Terraform] - Permissions to allow view resources related to Machine Learning practices within GCP"
  default = [
    "aiplatform.agentExamples.get",
    "aiplatform.agentExamples.list",
    "aiplatform.agents.get",
    "aiplatform.agents.list",
    "aiplatform.annotationSpecs.get",
    "aiplatform.annotationSpecs.list",
    "aiplatform.annotations.get",
    "aiplatform.annotations.list",
    "aiplatform.apps.get",
    "aiplatform.apps.list",
    "aiplatform.artifacts.get",
    "aiplatform.artifacts.list",
    "aiplatform.batchPredictionJobs.get",
    "aiplatform.batchPredictionJobs.list",
    "aiplatform.cacheConfigs.get",
    "aiplatform.cachedContents.get",
    "aiplatform.cachedContents.list",
    "aiplatform.consents.get",
    "aiplatform.contexts.get",
    "aiplatform.contexts.list",
    "aiplatform.contexts.queryContextLineageSubgraph",
    "aiplatform.customJobs.get",
    "aiplatform.customJobs.list",
    "aiplatform.dataItems.get",
    "aiplatform.dataItems.list",
    "aiplatform.dataLabelingJobs.get",
    "aiplatform.dataLabelingJobs.list",
    "aiplatform.datasetVersions.get",
    "aiplatform.datasetVersions.list",
    "aiplatform.datasets.get",
    "aiplatform.datasets.list",
    "aiplatform.deploymentResourcePools.get",
    "aiplatform.deploymentResourcePools.list",
    "aiplatform.deploymentResourcePools.queryDeployedModels",
    "aiplatform.edgeDeploymentJobs.get",
    "aiplatform.edgeDeploymentJobs.list",
    "aiplatform.edgeDeviceDebugInfo.get",
    "aiplatform.edgeDevices.get",
    "aiplatform.edgeDevices.list",
    "aiplatform.endpoints.get",
    "aiplatform.endpoints.list",
    "aiplatform.entityTypes.get",
    "aiplatform.entityTypes.list",
    "aiplatform.exampleStores.get",
    "aiplatform.exampleStores.list",
    "aiplatform.exampleStores.readExample",
    "aiplatform.executions.get",
    "aiplatform.executions.list",
    "aiplatform.executions.queryExecutionInputsAndOutputs",
    "aiplatform.extensions.get",
    "aiplatform.extensions.list",
    "aiplatform.featureGroups.get",
    "aiplatform.featureGroups.list",
    "aiplatform.featureOnlineStores.get",
    "aiplatform.featureOnlineStores.list",
    "aiplatform.featureViewSyncs.get",
    "aiplatform.featureViewSyncs.list",
    "aiplatform.featureViews.fetchFeatureValues",
    "aiplatform.featureViews.get",
    "aiplatform.featureViews.list",
    "aiplatform.featureViews.searchNearestEntities",
    "aiplatform.features.get",
    "aiplatform.features.list",
    "aiplatform.featurestores.get",
    "aiplatform.featurestores.list",
    "aiplatform.humanInTheLoops.get",
    "aiplatform.humanInTheLoops.list",
    "aiplatform.hyperparameterTuningJobs.get",
    "aiplatform.hyperparameterTuningJobs.list",
    "aiplatform.indexEndpoints.get",
    "aiplatform.indexEndpoints.list",
    "aiplatform.indexEndpoints.queryVectors",
    "aiplatform.indexes.get",
    "aiplatform.indexes.list",
    "aiplatform.locations.get",
    "aiplatform.locations.list",
    "aiplatform.metadataSchemas.get",
    "aiplatform.metadataSchemas.list",
    "aiplatform.metadataStores.get",
    "aiplatform.metadataStores.list",
    "aiplatform.modelDeploymentMonitoringJobs.get",
    "aiplatform.modelDeploymentMonitoringJobs.list",
    "aiplatform.modelDeploymentMonitoringJobs.searchStatsAnomalies",
    "aiplatform.modelEvaluationSlices.get",
    "aiplatform.modelEvaluationSlices.list",
    "aiplatform.modelEvaluations.get",
    "aiplatform.modelEvaluations.list",
    "aiplatform.modelMonitoringJobs.get",
    "aiplatform.modelMonitoringJobs.list",
    "aiplatform.modelMonitors.get",
    "aiplatform.modelMonitors.list",
    "aiplatform.modelMonitors.searchModelMonitoringAlerts",
    "aiplatform.modelMonitors.searchModelMonitoringStats",
    "aiplatform.models.get",
    "aiplatform.models.list",
    "aiplatform.nasJobs.get",
    "aiplatform.nasJobs.list",
    "aiplatform.nasTrialDetails.get",
    "aiplatform.nasTrialDetails.list",
    "aiplatform.notebookExecutionJobs.get",
    "aiplatform.notebookExecutionJobs.list",
    "aiplatform.notebookRuntimeTemplates.get",
    "aiplatform.notebookRuntimeTemplates.list",
    "aiplatform.notebookRuntimes.get",
    "aiplatform.notebookRuntimes.list",
    "aiplatform.operations.list",
    "aiplatform.persistentResources.get",
    "aiplatform.persistentResources.list",
    "aiplatform.pipelineJobs.get",
    "aiplatform.pipelineJobs.list",
    "aiplatform.provisionedThroughputRevisions.get",
    "aiplatform.provisionedThroughputRevisions.list",
    "aiplatform.provisionedThroughputs.get",
    "aiplatform.provisionedThroughputs.list",
    "aiplatform.ragCorpora.get",
    "aiplatform.ragCorpora.list",
    "aiplatform.ragCorpora.query",
    "aiplatform.ragEngineConfigs.get",
    "aiplatform.ragFiles.get",
    "aiplatform.ragFiles.list",
    "aiplatform.reasoningEngines.get",
    "aiplatform.reasoningEngines.list",
    "aiplatform.reasoningEngines.query",
    "aiplatform.schedules.get",
    "aiplatform.schedules.list",
    "aiplatform.sessionEvents.list",
    "aiplatform.sessions.get",
    "aiplatform.sessions.list",
    "aiplatform.specialistPools.get",
    "aiplatform.specialistPools.list",
    "aiplatform.specialistPools.update",
    "aiplatform.studies.get",
    "aiplatform.studies.list",
    "aiplatform.tensorboardExperiments.get",
    "aiplatform.tensorboardExperiments.list",
    "aiplatform.tensorboardRuns.get",
    "aiplatform.tensorboardRuns.list",
    "aiplatform.tensorboardTimeSeries.batchRead",
    "aiplatform.tensorboardTimeSeries.get",
    "aiplatform.tensorboardTimeSeries.list",
    "aiplatform.tensorboardTimeSeries.read",
    "aiplatform.tensorboards.get",
    "aiplatform.tensorboards.list",
    "aiplatform.trainingPipelines.get",
    "aiplatform.trainingPipelines.list",
    "aiplatform.trials.get",
    "aiplatform.trials.list",
    "aiplatform.tuningJobs.get",
    "aiplatform.tuningJobs.list",
    "artifactregistry.attachments.get",
    "artifactregistry.attachments.list",
    "artifactregistry.dockerimages.get",
    "artifactregistry.dockerimages.list",
    "artifactregistry.files.download",
    "artifactregistry.files.get",
    "artifactregistry.files.list",
    "artifactregistry.locations.get",
    "artifactregistry.locations.list",
    "artifactregistry.mavenartifacts.get",
    "artifactregistry.mavenartifacts.list",
    "artifactregistry.npmpackages.get",
    "artifactregistry.npmpackages.list",
    "artifactregistry.packages.get",
    "artifactregistry.packages.list",
    "artifactregistry.projectsettings.get",
    "artifactregistry.pythonpackages.get",
    "artifactregistry.pythonpackages.list",
    "artifactregistry.repositories.downloadArtifacts",
    "artifactregistry.repositories.get",
    "artifactregistry.repositories.list",
    "artifactregistry.repositories.listEffectiveTags",
    "artifactregistry.repositories.listTagBindings",
    "artifactregistry.repositories.readViaVirtualRepository",
    "artifactregistry.rules.get",
    "artifactregistry.rules.list",
    "artifactregistry.tags.get",
    "artifactregistry.tags.list",
    "artifactregistry.versions.get",
    "artifactregistry.versions.list",
    "logging.buckets.get",
    "logging.buckets.list",
    "logging.exclusions.get",
    "logging.exclusions.list",
    "logging.links.get",
    "logging.links.list",
    "logging.locations.get",
    "logging.locations.list",
    "logging.logEntries.list",
    "logging.logMetrics.get",
    "logging.logMetrics.list",
    "logging.logScopes.get",
    "logging.logScopes.list",
    "logging.logServiceIndexes.list",
    "logging.logServices.list",
    "logging.logs.list",
    "logging.operations.get",
    "logging.operations.list",
    "logging.queries.getShared",
    "logging.queries.listShared",
    "logging.queries.usePrivate",
    "logging.sinks.get",
    "logging.sinks.list",
    "logging.usage.get",
    "logging.views.get",
    "logging.views.list",
    "observability.scopes.get",
    "storage.folders.get",
    "storage.folders.list",
    "storage.managedFolders.get",
    "storage.managedFolders.list",
    "storage.objects.get",
    "storage.objects.list"
  ]
}

variable "ml_engineer_permissions" {
  type        = set(string)
  description = "[Terraform] - Basic permissions to allow Machine Learning Engineer role to use resources related to Machine Learning practices within GCP"
 }

variable "data_engineer_permissions" {
  type        = set(string)
  description = "[Terraform] - Basic permissions to allow Data Engineer role to use resources related to Machine Learning practices within GCP"
  }

variable "ml_data_scientist_permissions" {
  type        = set(string)
  description = "[Terraform] - Basic permissions to allow Machine Learning Data Scientist role to use resources related to Machine Learning practices within GCP"
  }

variable "ml_data_scientist_org_group" {
  type    = string
  default = "group:G_GCP_RISCCRVAR_DTSC@corp.caixa.gov.br"
}

variable "ml_engineer_org_group" {
  type    = string
  default = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
}

variable "data_engineer_org_group" {
  type    = string
  default = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
}
