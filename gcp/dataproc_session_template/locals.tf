# compute.networkUser exigido em VPC compartilhada: tanto a SA de execução da sessão
# quanto o Dataproc Service Agent (service-<num>@dataproc-accounts..., também usado
# pelo Dataproc Serverless) precisam da role no projeto host da subnet.
locals {
  shared_vpc_bindings = merge([
    for k, v in var.dataproc_session_template_settings : v.shared_vpc_host_project == null ? {} : {
      for suffix, member in {
        exec-sa  = "serviceAccount:${v.execution_settings.service_account}"
        dataproc = "serviceAccount:service-${data.google_project.shared_vpc_service_project[k].number}@dataproc-accounts.iam.gserviceaccount.com"
      } : "${k}-${suffix}" => {
        host_project = v.shared_vpc_host_project
        member       = member
      }
    }
  ]...)
}
