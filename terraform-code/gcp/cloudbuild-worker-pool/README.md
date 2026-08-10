# cloudbuild-worker-pool

Módulo para Cloud Build Private Worker Pools, no padrão SIPML.

## Arquivos
- `main.tf` — recurso `google_cloudbuild_worker_pool`, `for_each` sobre `worker_pool_settings`
- `variables.tf` — variável única `worker_pool_settings` (`map(object)`)
- `iam.tf` — IAM aditivo (`google_cloudbuild_worker_pool_iam_member`, `roles/cloudbuild.workerPoolUser`) para consumo cross-project
- `locals.tf` — flatten pool → worker_pool_users para o `for_each` do IAM
- `outputs.tf` — `worker_pool_ids`, `worker_pool_names`, `worker_pool_states`
- `example.tfvars` — exemplo de uso

## Convenções aplicadas
- Nome do recurso: `${each.key}_${each.value.sigla}_${terraform.workspace}`
- IAM aditivo (`_iam_member`) porque o consumo do pool é feito por outros projetos (ex.: SA do GitHub Actions em `prj-sipml-gateway-prd` usando o pool provisionado em `prj-spoke-modelagem`)
- `optional()` com defaults sensatos (`machine_type = e2-medium`, `disk_size_gb = 100`, `no_external_ip = true`, `peered_network_ip_range = /29`)
- `peered_network` montado a partir de `network_project_id` + `network_name`, permitindo peering com VPC de outro projeto

## Pendências ao integrar
- Confirmar se a VPC alvo já tem range `/29` livre reservado para o peering, ou ajustar `peered_network_ip_range`
- Conceder `roles/cloudbuild.workerPoolUser` também à service account nativa do Cloud Build do(s) projeto(s) consumidor(es), se ainda não coberta em `worker_pool_users`
- Habilitar a API `cloudbuild.googleapis.com` no projeto do pool antes do apply (fora do escopo deste módulo)
