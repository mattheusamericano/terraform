# cloudbuild-worker-pool

Módulo Terraform para provisionar **Cloud Build Private Worker Pools** peerados a uma VPC via Private Services Access, cada um já acompanhado de sua **service account dedicada** (com lista de permissões customizável por projeto/pipeline). Um único mapa de configuração (`worker_pool_settings`) dirige todo o módulo — a SA vem embutida em cada entrada, então tudo é resolvido com um só tipo de `for_each`.

## Recursos criados

- `google_cloudbuild_worker_pool.this` — um pool por entrada de `worker_pool_settings`; workers sem IP externo por padrão, peerados à VPC via `network_config`
- `google_service_account.cloudbuild` — uma SA por entrada de `worker_pool_settings` (bloco aninhado `service_account`), para uso em `service_account` do trigger/build
- `google_project_iam_member.worker_pool_user` — concede `roles/cloudbuild.workerPoolUser` (com IAM Condition restringindo ao pool específico) aos principals listados em `worker_pool_users`, permitindo consumo cross-project do pool
- `google_project_iam_member.cloudbuild_sa_roles` — concede à SA do Cloud Build cada role listada em `worker_pool_settings.*.service_account.roles`, no projeto correspondente
- `google_storage_bucket.cloudbuild_default` — um bucket `<project_id>_cloudbuild` por projeto entre os worker pools (dedup automático — vários pools no mesmo projeto geram um único bucket); é o bucket que o Cloud Build usa por convenção para staging do source (`gcloud builds submit`)

## Como usar

```hcl
module "cloudbuild_worker_pool" {
  source = "../../terraform-code/gcp/cloudbuild-worker-pool"

  worker_pool_settings = {
    modelagem = {
      project_id = "prj-spoke-modelagem"
      sigla      = "sipml"
      location   = "southamerica-east1"

      network_project_id = "prj-spoke-modelagem"
      network_name        = "vpc-spoke-modelagem"

      worker_pool_users = [
        "serviceAccount:sa-cloudbuild-gha@prj-sipml-gateway-prd.iam.gserviceaccount.com",
      ]

      annotations = { ambiente = "prd", squad = "sudea" }

      service_account = {
        display_name = "SA Cloud Build - pipeline modelagem SIPML"
        roles = [
          "roles/bigquery.jobUser",
          "roles/bigquery.user",
          "roles/storage.objectAdmin",
          "roles/artifactregistry.writer",
        ]
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `worker_pool_settings` | Mapa de configuração dos worker pools (SA embutida por entrada) | `map(object({...}))` | — | sim |
| `worker_pool_settings.*.project_id` | Projeto onde o pool e a SA são criados | `string` | — | sim |
| `worker_pool_settings.*.sigla` | Sigla do time/solução (compõe o nome do pool e o `account_id` da SA) | `string` | — | sim |
| `worker_pool_settings.*.location` | Região do pool | `string` | — | sim |
| `worker_pool_settings.*.network_project_id` | Projeto dono da VPC peerada | `string` | — | sim |
| `worker_pool_settings.*.network_name` | Nome da VPC peerada | `string` | — | sim |
| `worker_pool_settings.*.peered_network_ip_range` | CIDR /29 explícito dentro do range reservado (PSA) | `string` | `null` (auto-alocação) | não |
| `worker_pool_settings.*.machine_type` | Tipo de máquina dos workers | `string` | `e2-medium` | não |
| `worker_pool_settings.*.disk_size_gb` | Disco dos workers | `number` | `100` | não |
| `worker_pool_settings.*.no_external_ip` | Bloqueia IP externo nos workers | `bool` | `true` | não |
| `worker_pool_settings.*.worker_pool_users` | Principals com `roles/cloudbuild.workerPoolUser` no pool | `list(string)` | `[]` | não |
| `worker_pool_settings.*.annotations` | Annotations do pool | `map(string)` | `{}` | não |
| `worker_pool_settings.*.service_account` | Configuração da SA dedicada deste pool | `object({...})` | `{}` (usa os defaults internos) | não |
| `worker_pool_settings.*.service_account.display_name` | Nome de exibição da SA | `string` | `"SA do Cloud Build - gerenciada via Terraform"` | não |
| `worker_pool_settings.*.service_account.roles` | Lista de roles concedidas à SA no projeto — customizável por projeto/pipeline | `list(string)` | `["roles/bigquery.jobUser", "roles/bigquery.user", "roles/storage.objectAdmin"]` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `worker_pool_ids` | Mapa {chave => id} dos worker pools |
| `worker_pool_names` | Mapa {chave => name} dos worker pools |
| `worker_pool_states` | Mapa {chave => state} dos worker pools |
| `cloudbuild_sa_emails` | Mapa {chave => email} das SAs (usar em `service_account` do trigger) |
| `cloudbuild_sa_ids` | Mapa {chave => id} das SAs |
| `cloudbuild_default_bucket_names` | Mapa {project_id => name} dos buckets `<project_id>_cloudbuild` |

## Observações

- **Uma única variável, um único `for_each` conceitual**: `worker_pool_settings` é o único input do módulo. A SA de cada pool vive dentro do próprio objeto (`service_account`), então `main.tf` e `sa.tf` iteram sobre o mesmo mapa — não existe mais uma variável separada para a SA.
- **Pré-requisito de rede fora do escopo do módulo**: o pool exige um range reservado (Private Services Access) já anexado à conexão de Service Networking da VPC (`google_compute_global_address` purpose `VPC_PEERING` + `google_service_networking_connection`/`gcloud services vpc-peerings update`). Sem isso o `apply` falha com "Unable to allocate a new /29 block". Isso normalmente é responsabilidade do time de rede, não deste módulo.
- **IAM do worker pool é sempre a nível de projeto**: o provider `google` não expõe IAM por recurso para `google_cloudbuild_worker_pool` (Cloud Build não publica essa policy via API). A concessão é feita em `google_project_iam_member`, restringida ao pool específico via IAM Condition (`resource.name`). Se a condition não for aceita no seu ambiente, a alternativa documentada pela Google é aceitar a concessão em nível de projeto (remover o bloco `condition {}`).
- **`account_id` da SA tem limite de 30 caracteres** (`cb-<chave>-<sigla>-<workspace>`, minúsculo) — chaves/siglas longas podem estourar o limite; valide antes do `apply`.
- **SA custom no build**: ao usar `cloudbuild_sa_emails[...]` em `service_account` do trigger, é obrigatório declarar `options.logging = CLOUD_LOGGING_ONLY` (ou `GCS_ONLY` com `logsBucket` próprio) no `cloudbuild.yaml`/trigger — o Cloud Build não aceita mais o log padrão gerenciado pelo Google quando a SA não é a `default`.
- **Habilitar a API** `cloudbuild.googleapis.com` no projeto do pool antes do `apply` (via `project_service`/`module.project_services`, se a stack já tiver esse padrão) — fora do escopo deste módulo.
- Já existe um módulo `service_account` genérico no repositório (`terraform-code/gcp/service_account/`, sem IAM embutido). Optamos por manter a SA aqui em vez de compor com aquele módulo, seguindo o mesmo precedente de `bq_dataset` (SA dedicada + IAM inline no próprio módulo), já que a SA do Cloud Build nasce e é usada exclusivamente dentro deste contexto.
- **Bucket padrão do Cloud Build é por PROJETO, não por pool**: se dois pools de `worker_pool_settings` apontarem pro mesmo `project_id`, o módulo cria só **um** bucket `<project_id>_cloudbuild` (dedup em `locals.cloudbuild_default_buckets`) — criar um bucket por chave de pool faria dois resources tentarem gerenciar o mesmo nome globalmente único, quebrando o `plan`/`apply`. A `location` usada é a do primeiro pool encontrado para aquele projeto; se os pools do mesmo projeto tiverem `location` diferente entre si, ajuste manualmente qual deve prevalecer.
