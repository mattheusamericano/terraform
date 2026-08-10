# stack-example

Este diretório **não é um módulo Terraform reutilizável** — é um exemplo de **stack raiz** (root module) que demonstra como compor/orquestrar vários dos módulos deste repositório (`gcp/*`) para provisionar um ambiente completo de dados/ML no GCP em uma única aplicação: rede, IAM, armazenamento, bancos de dados, Kubernetes, Pub/Sub, Vertex AI Workbench, Cloud Composer (Airflow) e Workload Identity Federation.

Os arquivos ficam em `stack-example/stacks/`:

- `backend.tf` — configuração do backend remoto de state (GCS).
- `providers.tf` — versões e configuração dos providers `google`, `google-beta` e `random`.
- `locals.tf` — labels padrão aplicadas a todos os recursos e a lista de APIs do GCP a serem habilitadas no projeto.
- `variables.tf` — flags de habilitação (`enabled_*`) e os mapas de configuração (`*_settings`) de cada módulo consumido.
- `main.tf` — as chamadas (`module "..."`) para cada módulo do repositório, condicionadas pelas flags `enabled_*`.
- `tfvars/terraform.tfvars` — arquivo de valores de exemplo, com placeholders (`__algo__`) a serem substituídos antes do uso.

## O que esta stack provisiona

O `main.tf` instancia os seguintes módulos, cada um controlado por uma variável booleana de habilitação (`enabled_*`, default `true`):

| Módulo instanciado | Variável de habilitação | Origem (`source`) |
|---|---|---|
| `project_services` | (sempre criado) | `../../tf-modules-for-gcp/project_service` |
| `workbench` | `enabled_workbench` | `../../tf-modules-for-gcp/workbench` |
| `artifact_registry` | `enabled_workbench` (reaproveita a mesma flag do Workbench) | `../../tf-modules-for-gcp/artifact_registry` |
| `pub_sub` | `enabled_pubsub` | `../../tf-modules-for-gcp/pubsub` |
| `bucket` | `enabled_bucket` | `../../tf-modules-for-gcp/bucket` |
| `dataform_repository` | `enabled_dataform_repo` | `../../tf-modules-for-gcp/dataform` |
| `cloud_sql` | `enabled_sql` | `../../tf-modules-for-gcp/cloud_sql` |
| `cloud_sql_database` | `enabled_sql` | `../../tf-modules-for-gcp/cloud_sql_database` |
| `bq_dataset` | `enabled_bq_dataset` | `../../tf-modules-for-gcp/bq_dataset` |
| `firestore` | `enabled_firestore` | `../../tf-modules-for-gcp/firestore` |
| `gke` | `enabled_gke` | `../../tf-modules-for-gcp/gke` |
| `gke_nodepool` | `enabled_gke` (reaproveita a mesma flag do GKE) | `../../tf-modules-for-gcp/gke_nodepool` |
| `wipool` | `enabled_wipool` | `../../tf-modules-for-gcp/wipool` |
| `airflow_composer` | `enabled_airflow_composer` | `../../tf-modules-for-gcp/airflow_composer` |
| `colab_runtime_template` | `enabled_colab_rt_template` | `../../tf-modules-for-gcp/colab_runtime` |

Quando uma flag está em `false`, o `main.tf` passa um mapa vazio (`{}`) para o `*_settings` do módulo correspondente, então o módulo é instanciado mas não cria nenhum recurso (todos os `for_each` internos ficam vazios).

## Encadeamento de dependências

- `workbench` e `artifact_registry` dependem de `project_services` (as APIs precisam estar habilitadas antes).
- `workbench` também depende de `artifact_registry` (via `depends_on`).
- `pub_sub` depende de `project_services`.
- `cloud_sql_database` depende de `cloud_sql` (a instância precisa existir antes do database).
- `gke_nodepool` depende de `gke` (o cluster precisa existir antes do node pool).
- Os demais módulos (`bucket`, `dataform_repository`, `bq_dataset`, `firestore`, `wipool`, `airflow_composer`, `colab_runtime_template`) não declaram `depends_on` explícito neste `main.tf`.

## Labels e APIs comuns

`locals.tf` define:

- `common_labels` — um conjunto fixo de labels (`ambiente`, `equipeinfra`, `equipesolucao`, `solucao`, `provimento`, `workload`) que é mesclado (`merge`) automaticamente em cada entrada de configuração antes de ser passado ao módulo correspondente. Ou seja, você não precisa (nem deve) incluir `labels` manualmente nos mapas `*_settings` do `terraform.tfvars` — a stack injeta essas labels por conta própria.
- `apis_list` — a lista de Service APIs do GCP habilitadas via módulo `project_services` (Vertex AI, BigQuery, Dataproc, Composer, GKE, Pub/Sub, Secret Manager, etc.).

## Backend e Providers

- `backend.tf` usa backend remoto `gcs`, com `bucket = "__state-bucket__"` e `prefix = "terraform/tfstate"`. O nome do bucket é um placeholder e precisa ser substituído pelo bucket real de state antes do `terraform init`.
- `providers.tf` fixa as versões `google ~> 7.5.0`, `google-beta ~> 7.5.0` e `random ~> 3.6.3`, e configura `project = "terraform"` (placeholder) e `region = "__region__"` (placeholder) tanto no provider `google` quanto no `google-beta`. Esses valores também precisam ser ajustados/substituídos — o comentário no arquivo sugere o padrão real esperado (`"prj-__project__-__environment__-cef"`).

## Como usar

1. Copie `tfvars/terraform.tfvars` (ou edite uma cópia) e substitua todos os placeholders no formato `__algo__` (ex.: `__project_id__`, `__region__`, `__sigla__`, `__environment__`, `__name_vpc_shared__`, etc.) pelos valores reais do ambiente de destino.
2. Ajuste `providers.tf` (`project`, `region`) e `backend.tf` (`bucket`) com os valores reais, já que eles não são parametrizados via variável.
3. Rode os comandos a partir de `stack-example/stacks/`:

```bash
cd gcp/stack-example/stacks

terraform init

terraform plan  -var-file="tfvars/terraform.tfvars"
terraform apply -var-file="tfvars/terraform.tfvars"
```

4. Para desabilitar algum módulo (ex.: não provisionar GKE nesta execução), defina a flag correspondente como `false` no `.tfvars`, por exemplo:

```hcl
enabled_gke = false
```

## Observações

- **Atenção aos caminhos de `source`**: todos os módulos são referenciados como `../../tf-modules-for-gcp/<modulo>` (dois níveis acima de `stacks/`, dentro de uma pasta `tf-modules-for-gcp`). Nesta cópia do repositório, os módulos reais estão diretamente em `gcp/<modulo>` (ex.: `gcp/pubsub`, `gcp/workbench`), e **não** existe uma pasta `gcp/tf-modules-for-gcp/`. Ou seja, este `main.tf` é ilustrativo de uma convenção de nomenclatura de outro layout de repositório — para rodar esta stack de fato neste repositório, os `source` precisam ser ajustados para apontar para os módulos reais (ex.: `../../pubsub`, `../../workbench`, etc.).
- Cada `*_settings` do `main.tf` é construído dinamicamente com `{for k, v in var.X_settings : k => merge(v, { labels = local.common_labels })}`, portanto os objetos declarados em `variables.tf` desta stack **não** precisam (e no caso de `pubsub_topic_settings`/`pubsub_settings`/`workbench_settings`, etc., realmente não incluem) o campo `labels` — ele é injetado automaticamente pela stack antes de chegar ao módulo.
- O arquivo `terraform.tfvars` fornecido é um **template**, não um arquivo pronto para uso — todos os tokens `__xxx__` (ex.: `__project_id__`, `__environment__`, `__sigla__`, `__region__`, `__name_vpc_shared__`, `__name_vpc_subnet__`, tamanhos de disco, tipos de máquina, etc.) precisam ser substituídos por valores reais antes de rodar `terraform plan`/`apply`. Isso sugere que, no fluxo real deste time, esse arquivo é gerado/substituído por uma pipeline de CI/CD (ex.: via `sed`/templating) a partir de um arquivo de exemplo.
- As variáveis `project_id` e `network_project_id` (usadas pelo módulo `project_services` e por `airflow_composer`) são strings simples, obrigatórias e sem default — precisam ser definidas no `.tfvars`.
- Como cada módulo é sempre instanciado (mesmo quando a flag `enabled_*` é `false`, apenas com mapa vazio), `terraform plan` sempre avalia todos os módulos da stack; desabilitar uma flag apenas evita a criação de recursos dentro daquele módulo, não a sua instanciação.
