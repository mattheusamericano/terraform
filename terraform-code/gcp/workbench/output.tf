output "instance_names" {
  description = "Nome de cada instância do Workbench criada."
  value = {
    for k, v in google_workbench_instance.instance : k => v.name
  }
}

output "instance_ids" {
  description = "ID completo de cada instância no formato projects/PROJECT/locations/LOCATION/instances/NAME."
  value = {
    for k, v in google_workbench_instance.instance : k => v.id
  }
}

output "instance_states" {
  description = "Estado atual de cada instância (ex: ACTIVE, STOPPED)."
  value = {
    for k, v in google_workbench_instance.instance : k => v.state
  }
}

output "proxy_uris" {
  description = "URI do proxy JupyterLab de cada instância."
  value = {
    for k, v in google_workbench_instance.instance : k => v.proxy_uri
  }
}

output "service_account_emails" {
  description = "E-mail da Service Account de cada instância."
  value = {
    for k, v in google_service_account.workbench_sa : k => v.email
  }
}

output "service_account_members" {
  description = "Member string de cada SA (serviceAccount:EMAIL), útil para bindings IAM externas."
  value = {
    for k, v in google_service_account.workbench_sa : k => v.member
  }
}
