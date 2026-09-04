locals {
  # Agrupa por project_id, usado em data.tf pra criar só um data.google_project
  # e um Service Agent (notebooks/compute) por projeto, mesmo com várias
  # instâncias de Workbench no mesmo projeto.
  unique_projects = {
    for k, v in var.workbench_settings :
    v.project_id => v...
  }

  unique_projects_flat = {
    for key, val in local.unique_projects :
    key => val[0]
  }

  # Agrupa por project_id+kms_project_id+region+key_ring+key_crypto, evitando
  # conceder o mesmo IAM binding de KMS repetidamente para os Service Agents.
  kms_unique_bindings = {
    for k, v in var.workbench_settings :
    "${v.project_id}||${v.kms_project_id}||${v.region}||${v.key_ring}||${v.key_crypto}" => v...
  }

  kms_unique_bindings_flat = {
    for key, val in local.kms_unique_bindings :
    key => val[0]
  }

  # Agrupa por network_project_id+region+name_subnet_vpc_shared, evitando
  # duplicar o binding de roles/compute.networkUser do Service Agent do
  # Notebooks na mesma sub-rede.
  network_unique_bindings = {
    for k, v in var.workbench_settings :
    "${v.network_project_id}||${v.region}||${v.name_subnet_vpc_shared}" => v...
  }

  network_unique_bindings_flat = {
    for key, val in local.network_unique_bindings :
    key => val[0]
  }

  # Conjunto padrão de roles da SA no próprio projeto — usado quando
  # workbench_settings.<chave>.project_roles é null (comportamento default,
  # igual ao histórico do módulo).
  _sa_base_project_roles = [
    "roles/artifactregistry.writer",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/bigquery.user",
    "roles/storage.objectUser",
    "roles/osconfig.projectFeatureSettingsViewer",
    "roles/aiplatform.user",
    "roles/run.developer",
    "roles/logging.logWriter",
    "roles/serviceusage.serviceUsageViewer",
    "roles/dataproc.editor",
    "roles/dataproc.worker",
  ]

  # Flatten multi-nível (Workbench -> lista de roles no próprio projeto) para
  # viabilizar o for_each do IAM em iam.tf. O conjunto efetivo de cada Workbench
  # é project_roles (se informado, substitui o padrão) ou _sa_base_project_roles
  # (padrão do módulo), sempre somado a extra_project_roles.
  sa_own_project_iam_bindings = {
    for pair in flatten([
      for wb_key, wb in var.workbench_settings : [
        for role in concat(
          coalesce(wb.project_roles, local._sa_base_project_roles),
          wb.extra_project_roles
          ) : {
          key     = "${wb_key}||${role}"
          project = wb.project_id
          role    = role
          wb_key  = wb_key
        }
      ]
    ]) : pair.key => pair
  }

  # Flatten multi-nível (Workbench -> lista de {project_id, role} em
  # cross_project_roles) para viabilizar o for_each do IAM cross-project em iam.tf.
  sa_cross_project_iam_bindings = {
    for pair in flatten([
      for wb_key, wb in var.workbench_settings : [
        for cp in wb.cross_project_roles : {
          key        = "${wb_key}||${cp.project_id}||${cp.role}"
          project_id = cp.project_id
          role       = cp.role
          wb_key     = wb_key
        }
      ]
    ]) : pair.key => pair
  }
}
