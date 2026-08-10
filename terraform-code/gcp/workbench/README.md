# workbench

Módulo Terraform responsável por provisionar instâncias do **Vertex AI Workbench** (`google_workbench_instance`) no GCP, incluindo toda a infraestrutura de suporte necessária: Service Account dedicada por instância, habilitação dos Service Agents do Notebooks e do Compute Engine, criptografia de disco via CMEK (KMS) e concessão das permissões de IAM necessárias para que a instância opere em uma Shared VPC e acesse BigQuery, Artifact Registry, Vertex AI, Cloud Storage, entre outros serviços.

## Recursos criados

- `google_workbench_instance.instance` — cria a instância do Vertex AI Workbench propriamente dita, para cada chave do mapa `var.workbench_settings`.
- `google_service_account.workbench_sa` — cria a Service Account dedicada de cada instância do Workbench (definida em `sa.tf`).
- `google_project_service_identity.notebooks_identity` — habilita/obtém o Service Agent do serviço `notebooks.googleapis.com` em cada projeto único presente em `workbench_settings`.
- `google_project_service_identity.compute_identity` — habilita/obtém o Service Agent do serviço `compute.googleapis.com` em cada projeto único presente em `workbench_settings`.
- `google_project_iam_member.workbench_sa_own_project_roles` — concede à SA de cada Workbench o conjunto de roles base do projeto (`roles/artifactregistry.writer`, `roles/bigquery.dataEditor`, `roles/bigquery.jobUser`, `roles/bigquery.user`, `roles/storage.objectUser`, `roles/osconfig.projectFeatureSettingsViewer`, `roles/aiplatform.user`, `roles/run.developer`, `roles/logging.logWriter`, `roles/serviceusage.serviceUsageViewer`, `roles/dataproc.editor`, `roles/dataproc.worker`) mais as roles extras definidas em `extra_project_roles`.
- `google_project_iam_member.workbench_bigquery_viewer` — concede à SA de cada Workbench a role `roles/bigquery.dataViewer` em um projeto de Big Data fixo, com ID hardcoded `bigdata-1744049006`.
- `google_kms_crypto_key_iam_member.workbench_kms` — concede à SA de cada Workbench a role `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave KMS informada, necessária para que a instância consiga usar a chave CMEK.
- `google_kms_crypto_key_iam_member.workbench_kms_notebook` — concede a mesma role de KMS ao Service Agent do Notebooks, por combinação única de projeto/KMS/região/keyring/chave.
- `google_kms_crypto_key_iam_member.workbench_kms_compute` — concede a mesma role de KMS ao Service Agent do Compute Engine (`service-<project_number>@compute-system.iam.gserviceaccount.com`), por combinação única de projeto/KMS/região/keyring/chave.
- `google_compute_subnetwork_iam_member.ai-service-agent-role-network` — concede à SA de cada Workbench a role `roles/compute.networkUser` na sub-rede da Shared VPC informada.
- `google_compute_subnetwork_iam_member.ai-service-agent-role-network-svc-agent` — concede a mesma role `roles/compute.networkUser` ao Service Agent do Notebooks, por combinação única de projeto de rede/região/sub-rede.

## Data sources utilizados

- `data.google_project.project` — resolve os projetos únicos presentes em `workbench_settings`, usado para obter o número do projeto (`project.number`) e montar o e-mail do Service Agent do Compute Engine.

## Como usar

```hcl
module "workbench" {
  source = "./gcp/workbench"

  workbench_settings = {
    "wb-01" = {
      project_id                = "meu-projeto-gcp"
      region                    = "us-central1"
      zone                      = "c"
      sigla                     = "sqa"
      network_project_id        = "prj-network-services-prd-cef"
      kms_project_id            = "prj-hsm-services-prd"
      workbench_machine_type    = "n1-standard-4"
      workbench_disk_size_gb    = "150"
      workbench_disk_type       = "PD_BALANCED"
      workbench_disk_encryption = "CMEK"
      key_ring                  = "workbhsmNPRDring"
      key_crypto                = "workbNPRDSYMAES256hsm001"
      name_vpc_shared           = "vpc-shared"
      name_subnet_vpc_shared    = "subnet-shared-us-central1"
      sa_account_id             = "sa-wb-01-sqa-prd"
      auto_shutdown             = "3600"
      extra_project_roles       = ["roles/secretmanager.secretAccessor"]

      labels = {
        ambiente = "producao"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `workbench_settings` | Mapa de configurações das instâncias do Vertex AI Workbench a serem criadas. A chave do mapa é usada como parte do nome da instância. Ver estrutura detalhada abaixo. | `map(object({...}))` | — | Sim |

### Estrutura de `workbench_settings`

Cada entrada do mapa representa uma instância do Workbench (com sua respectiva Service Account, IAM e criptografia) e aceita os seguintes campos:

| Campo | Tipo | Default | Descrição |
|-------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde a instância e a Service Account serão criadas. |
| `region` | `string` | — | Região da instância, também usada para compor a `location` (`${region}-${zone}`) e para localizar a chave KMS e a sub-rede. |
| `zone` | `string` | — | Sufixo de zona (ex.: `"c"`), combinado com `region` para formar a `location` da instância. |
| `sigla` | `string` | — | Sufixo de nomenclatura usado no nome final da instância. |
| `network_project_id` | `string` | — | Projeto da Shared VPC onde a sub-rede está localizada. |
| `kms_project_id` | `string` | — | Projeto onde o keyring/chave KMS estão localizados. |
| `workbench_machine_type` | `string` | — | Tipo de máquina da instância (ex.: `n1-standard-4`). |
| `workbench_disk_size_gb` | `string` | — | Tamanho do disco de dados em GB. |
| `workbench_disk_type` | `string` | — | Tipo do disco de dados (ex.: `PD_BALANCED`). |
| `workbench_disk_encryption` | `string` | — | Modo de criptografia do disco de dados e de boot (ex.: `CMEK`). |
| `key_ring` | `string` | — | Nome do keyring KMS usado para criptografar os discos. |
| `key_crypto` | `string` | — | Nome da chave criptográfica KMS usada para criptografar os discos. |
| `name_vpc_shared` | `string` | — | Nome da VPC compartilhada à qual a instância se conecta. |
| `name_subnet_vpc_shared` | `string` | — | Nome da sub-rede da Shared VPC à qual a instância se conecta. |
| `repository_name` | `optional(string)` | `null` | Nome de um repositório do Artifact Registry. Declarado na variável, mas atualmente não utilizado no `main.tf` (o bloco `container_image` está comentado). |
| `workbench_members` | `optional(list(string))` | `null` | Declarado na variável, mas não é consumido em nenhum recurso do módulo atualmente. |
| `sa_account_id` | `string` | — | `account_id` da Service Account dedicada da instância. |
| `auto_shutdown` | `optional(string, "3600")` | `"3600"` | Tempo de ociosidade (em segundos) até o desligamento automático (`idle-timeout-seconds`). |
| `labels` | `map(any)` | — | Labels aplicadas à instância do Workbench. |
| `extra_project_roles` | `optional(list(string), [])` | `[]` | Roles adicionais concedidas à Service Account da instância no próprio projeto, além do conjunto base fixo definido no módulo. |
| `wb_reservation_name` | `optional(string)` | `null` | Nome de uma reserva específica do Compute Engine a ser consumida pela instância (`reservation_affinity`). Quando informado, cria o bloco `reservation_affinity`. |
| `wbrv_machine_type` | `optional(string)` | `null` | Declarado na variável, mas não é consumido em nenhum recurso do módulo atualmente. |
| `wbrv_accelerator_type` | `optional(string)` | `null` | Tipo de acelerador (GPU) anexado à instância. Quando informado (não nulo/vazio), cria o bloco `accelerator_configs`. |
| `wbrv_accelerator_count` | `optional(number)` | `null` | Quantidade de aceleradores (`core_count`) do tipo informado em `wbrv_accelerator_type`. |

## Outputs

| Nome | Descrição |
|------|-----------|
| `instance_names` | Nome de cada instância do Workbench criada. |
| `instance_ids` | ID completo de cada instância, no formato `projects/PROJECT/locations/LOCATION/instances/NAME`. |
| `instance_states` | Estado atual de cada instância (ex.: `ACTIVE`, `STOPPED`). |
| `proxy_uris` | URI do proxy JupyterLab de cada instância. |
| `service_account_emails` | E-mail da Service Account de cada instância. |
| `service_account_members` | Member string de cada Service Account (`serviceAccount:EMAIL`), útil para bindings de IAM externos a este módulo. |

## Observações

- O nome final da instância segue o padrão `${chave}-${sigla}-${terraform.workspace}`; a `location` é montada como `${region}-${zone}` (ex.: `region = "us-central1"` e `zone = "c"` resultam em `us-central1-c`).
- O módulo agrupa entradas de `workbench_settings` por chaves compostas para evitar a criação de recursos duplicados quando múltiplas instâncias compartilham o mesmo contexto:
  - `unique_projects` (em `data.tf`) agrupa por `project_id`, usado para criar apenas um Service Agent (`notebooks_identity`, `compute_identity`) e um `data.google_project` por projeto, mesmo que existam várias instâncias no mesmo projeto.
  - `kms_unique_bindings` (em `iam.tf`) agrupa por `project_id`+`kms_project_id`+`region`+`key_ring`+`key_crypto`, evitando conceder o mesmo IAM binding de KMS repetidamente para os Service Agents.
  - `network_unique_bindings` (em `iam.tf`) agrupa por `network_project_id`+`region`+`name_subnet_vpc_shared`, evitando duplicar o binding de `roles/compute.networkUser` do Service Agent do Notebooks na mesma sub-rede.
- Cada Service Account de instância recebe automaticamente, no próprio projeto, um conjunto fixo de 12 roles (leitura/escrita em BigQuery, Artifact Registry, Storage, Vertex AI, Cloud Run, logging, Dataproc, etc.) mais qualquer role adicional definida em `extra_project_roles`.
- **Atenção**: o recurso `google_project_iam_member.workbench_bigquery_viewer` concede `roles/bigquery.dataViewer` a todas as SAs de Workbench em um projeto de Big Data **fixo no código** (`bigdata-1744049006`), independentemente do projeto configurado em `workbench_settings`. Isso é um valor hardcoded específico deste repositório/ambiente, não parametrizável via variáveis.
- A criptografia de disco (boot e dados) é sempre feita via CMEK, usando a chave montada a partir de `kms_project_id`, `region`, `key_ring` e `key_crypto`; o módulo concede automaticamente a role de `cloudkms.cryptoKeyEncrypterDecrypter` tanto para a SA da instância quanto para os Service Agents do Notebooks e do Compute Engine sobre essa mesma chave.
- A instância é conectada obrigatoriamente a uma Shared VPC (`network_project_id`/`name_vpc_shared`/`name_subnet_vpc_shared`) e não possui IP público (`disable_public_ip = true`); o módulo concede `roles/compute.networkUser` na sub-rede tanto para a SA da instância quanto para o Service Agent do Notebooks.
- Os blocos `accelerator_configs` (GPU) e `reservation_affinity` são dinâmicos e só são criados quando `wbrv_accelerator_type`/`wb_reservation_name` são informados, respectivamente.
- `google_workbench_instance.instance` depende explicitamente da Service Account (`google_service_account.workbench_sa`) e do binding de KMS (`google_kms_crypto_key_iam_member.workbench_kms`), garantindo que a instância só seja criada após a SA existir e ter permissão de uso da chave.
- Os campos `repository_name`, `workbench_members` e `wbrv_machine_type` estão declarados em `workbench_settings`, mas não são consumidos por nenhum recurso do módulo no estado atual do código (o bloco `container_image` que usaria `repository_name` está comentado em `main.tf`).
