# Flatten dos bindings de compute.networkUser exigidos em cenários de VPC compartilhada:
# tanto o service agent do Dataproc (service-<num>@dataproc-accounts...) quanto o
# service agent do Cloud Services (service-<num>@cloudservices...) precisam da role
# no projeto host da VPC.
locals {
  shared_vpc_bindings = merge([
    for k, v in var.cluster_settings : v.shared_vpc_host_project == null ? {} : {
      for suffix, sa_email in {
        dataproc-accounts = "service-${data.google_project.shared_vpc_service_project[k].number}@dataproc-accounts.iam.gserviceaccount.com"
        cloudservices      = "service-${data.google_project.shared_vpc_service_project[k].number}@cloudservices.gserviceaccount.com"
      } : "${k}-${suffix}" => {
        host_project = v.shared_vpc_host_project
        member       = "serviceAccount:${sa_email}"
      }
    }
  ]...)

  additional_bindings = merge([
    for k, v in var.cluster_settings : {
      for bk, b in v.additional_project_bindings : "${k}-${bk}" => b
    }
  ]...)
}
