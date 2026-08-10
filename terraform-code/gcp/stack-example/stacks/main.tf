#
#WORKBENCH
#

module "workbench" {
    source      = "../../tf-modules-for-gcp/workbench"
    workbench_settings = var.enabled_workbench == true ? {for k, v in var.workbench_settings : k => merge(v, { labels = local.common_labels }) } : {}
    
    depends_on = [
      module.project_services,
      module.artifact_registry
    ]
}

#
#PROJECT_SERVICES
#
 module "project_services" {
   source             = "../../tf-modules-for-gcp/project_service"
   project_id         = var.project_id
   apis_list          = local.apis_list

 }

#
#ARTIFACT_REGISTRY
#
module "artifact_registry" {
    source      = "../../tf-modules-for-gcp/artifact_registry"
    artifact_registry_settings = var.enabled_workbench == true ? {for k, v in var.artifact_registry_settings : k => merge(v, { labels = local.common_labels }) } : {}
    
    depends_on = [
      module.project_services
    ]
}

#
#PUB_SUB
#
module "pub_sub" {
    source      = "../../tf-modules-for-gcp/pubsub"
    pubsub_settings = var.enabled_pubsub == true ? {for k, v in var.pubsub_settings : k => merge(v, { labels = local.common_labels }) } : {}
    pubsub_topic_settings = var.enabled_pubsub == true ? {for k, v in var.pubsub_topic_settings : k => merge(v, { labels = local.common_labels }) } : {}
    
    depends_on = [
      module.project_services
    ]
}

#
#BUCKET_OBJECT
#
module "bucket" {
    source      = "../../tf-modules-for-gcp/bucket"
    bucket_settings = var.enabled_bucket == true ? {for k, v in var.bucket_settings : k => merge(v, { labels = local.common_labels }) } : {}
    
}

#
#DATAFORM_REPOSITORY
#
module "dataform_repository" {
    source      = "../../tf-modules-for-gcp/dataform"
    dataform_repository_settings = var.enabled_dataform_repo == true ? {for k, v in var.dataform_repository_settings : k => merge(v, { labels = local.common_labels }) } : {}
    
}

#
#CLOUD_SQL
#
module "cloud_sql" {
    source      = "../../tf-modules-for-gcp/cloud_sql"
    cloud_sql_instance_settings = var.enabled_sql == true ? {for k, v in var.cloud_sql_instance_settings : k => merge(v, { labels = local.common_labels }) } : {}
}

#
#CLOUD_SQL_DATABASE
#
module "cloud_sql_database" {
    source      = "../../tf-modules-for-gcp/cloud_sql_database"
    cloud_sql_database_settings = var.enabled_sql == true ? {for k, v in var.cloud_sql_database_settings : k => merge(v, { labels = local.common_labels }) } : {}

    depends_on = [
      module.cloud_sql
    ]    
}

#
#BIGQUERY_DATASET
#
module "bq_dataset" {
    source      = "../../tf-modules-for-gcp/bq_dataset"
    bq_dataset_settings = var.enabled_bq_dataset == true ? {for k, v in var.bq_dataset_settings : k => merge(v, { labels = local.common_labels }) } : {}    
}

#
#Firestore_Database
#
module "firestore" {
    source      = "../../tf-modules-for-gcp/firestore"
    firestore_settings = var.enabled_firestore == true ? {for k, v in var.firestore_settings : k => merge(v, { labels = local.common_labels }) } : {}    
}

#
#GKE
#
module "gke" {
    source      = "../../tf-modules-for-gcp/gke"
    gke_cluster_settings = var.enabled_gke == true ? {for k, v in var.gke_cluster_settings : k => merge(v, { labels = local.common_labels }) } : {}    
}

#
#GKE_Nodepool
#
module "gke_nodepool" {
    source      = "../../tf-modules-for-gcp/gke_nodepool"
    gke_nodepool_settings = var.enabled_gke == true ? {for k, v in var.gke_nodepool_settings : k => merge(v, { labels = local.common_labels }) } : {}    

    depends_on = [
        module.gke
    ]
}

#
#Workload_Identity_Pool
#
module "wipool" {
    source      = "../../tf-modules-for-gcp/wipool"
    wipool_settings = var.enabled_wipool == true ? {for k, v in var.wipool_settings : k => merge(v, { labels = local.common_labels }) } : {}    

}

#
#Airflow_Composer
#
module "airflow_composer" {
    source      = "../../tf-modules-for-gcp/airflow_composer"
    composer_settings   = var.enabled_airflow_composer == true ? {for k, v in var.composer_settings : k => merge(v, { labels = local.common_labels }) } : {}    
    project_id          = var.project_id
    network_project_id  = var.network_project_id
}

#
#COLAB_RUNTIME_TEMPLATE
#
module "colab_runtime_template" {
    source      = "../../tf-modules-for-gcp/colab_runtime"
    colab_runtime_template_settings = var.enabled_colab_rt_template == true ? {for k, v in var.colab_runtime_template_settings : k => merge(v, { labels = local.common_labels }) } : {}
    
}
