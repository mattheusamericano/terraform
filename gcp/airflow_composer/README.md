# airflow_composer

Módulo Terraform que provisiona um ou mais ambientes **Cloud Composer 3** (Airflow gerenciado) no GCP, incluindo a Service Account dedicada de cada ambiente e todo o IAM necessário para operação em uma topologia de **Shared VPC** (rede em um projeto host, workloads em um projeto de serviço). Também cuida, de forma opcional, da criptografia dos ambientes e dos buckets associados via Cloud KMS.

O módulo é orientado a `for_each`: cada chave do mapa `composer_settings` gera um ambiente Composer completo (instância + Service Account + bindings de IAM), permitindo criar vários ambientes de uma única vez a partir do mesmo módulo.

## Recursos criados

- `google_composer_environment.composer` — o ambiente Cloud Composer 3 em si (ambiente privado, `enable_private_environment`/`enable_private_builds_only`), com configuração de software, workloads (scheduler, triggerer, web server, workers), tamanho do ambiente, node config em Shared VPC, criptografia KMS opcional, janela de manutenção opcional e retenção de metadados do Airflow fixa em 30 dias.
- `google_service_account.composer_sa` — Service Account dedicada a cada ambiente, usada como identidade dos nós do Composer.
- `google_project_iam_member.composer_sa_host_network` — concede `roles/compute.networkUser` à SA do Composer no projeto host da Shared VPC (`network_project_id`).
- `google_project_iam_member.composer_sa_roles` — concede, no projeto de serviço, cada role listada em `sa_roles` à SA do respectivo ambiente (relação N:N entre ambientes e roles, "achatada" via `flatten`).
- `google_project_iam_member.composer_agent_host_network` — concede `roles/compute.networkUser`, no projeto informado em `var.project_id`, ao Service Agent do Composer (`service-<number>@cloudcomposer-accounts.iam.gserviceaccount.com`).
- `google_project_iam_member.composer_agent_roles` — concede `roles/composer.ServiceAgentV2Ext` ao Service Agent do Composer no projeto `var.project_id`.
- `google_project_iam_member.composer_agent_shared_vpc` — concede `roles/composer.sharedVpcAgent` ao Service Agent do Composer no projeto host da Shared VPC (`var.network_project_id`).
- `google_project_iam_member.composer_bigquery_viewer` — concede `roles/bigquery.dataViewer` à SA de cada ambiente no projeto fixo `bigdata-1744049006` (projeto corporativo de Big Data).
- `google_kms_crypto_key_iam_member.composer_sa_kms` — concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` à Service Agent do Composer na chave KMS, para combinações únicas de projeto/keyring/key.
- `google_kms_crypto_key_iam_member.composer_bucket_sa_kms` — concede a mesma role de KMS à Service Agent do GCS (`gs-project-accounts.iam.gserviceaccount.com`), necessária para criptografar o bucket de DAGs/logs do Composer.
- `data.google_project.service` — resolve o número do projeto informado em `var.project_id` (usado para montar o e-mail do Service Agent do Composer).
- `data.google_kms_key_ring.composer` / `data.google_kms_crypto_key.composer` — resolvem o keyring/chave KMS de cada ambiente quando `key_ring`/`key_crypto` são informados.
- `data.google_project.project` — resolve o número de cada projeto de serviço único (usado nos bindings de KMS).

## Como usar

```hcl
module "airflow_composer" {
  source = "./gcp/airflow_composer"

  project_id         = "prj-dados-dev"
  network_project_id = "prj-network-shared-dev"

  composer_settings = {
    ingestao = {
      project_id         = "prj-dados-dev"
      network_project_id = "prj-network-shared-dev"
      sigla              = "eng"
      region             = "southamerica-east1"

      network_name           = "vpc-shared-dev"
      subnetwork_name        = "snet-composer-dev"
      pods_ip_range_name     = "pods-range"
      services_ip_range_name = "services-range"

      image_version    = "composer-3-airflow-2.9"
      environment_size = "ENVIRONMENT_SIZE_SMALL"

      scheduler_cpu       = 1
      scheduler_memory_gb = 2
      worker_min_count    = 1
      worker_max_count    = 3

      sa_roles = [
        "roles/composer.worker",
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/storage.objectAdmin",
        "roles/secretmanager.secretAccessor",
      ]

      pypi_packages = {
        pandas = ""
      }

      enable_data_lineage = true

      kms_project_id = "prj-kms-dev"
      key_ring       = "kr-composer"
      key_crypto     = "key-composer"

      maintenance_window = {
        start_time = "2024-01-01T06:00:00Z"
        end_time   = "2024-01-01T10:00:00Z"
        recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
      }

      labels = {
        squad = "engenharia-dados"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `composer_settings` | Mapa de configurações dos ambientes Cloud Composer 3 | `map(object({...}))` | — | sim |
| `project_id` | Projeto onde vive o Composer e onde é resolvida/autorizada a Service Agent do Composer (sem `description` no código; ver `data.tf`/`iam.tf`) | `string` | — | sim |
| `network_project_id` | Projeto host da Shared VPC, usado nos bindings de IAM da Service Agent do Composer (`roles/composer.sharedVpcAgent`) | `string` | — | sim |

### Estrutura de cada item de `composer_settings`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `project_id` | `string` | — | Projeto de serviço onde o ambiente é criado |
| `network_project_id` | `string` | — | Projeto host da Shared VPC usada pelo ambiente |
| `sigla` | `string` | — | Sigla usada na composição do nome do ambiente/SA |
| `region` | `string` | — | Região do ambiente Composer |
| `image_version` | `string` | `"composer-3-airflow-2.9"` | Versão da imagem do Composer/Airflow |
| `network_name` | `string` | — | Nome da VPC compartilhada |
| `subnetwork_name` | `string` | — | Nome da sub-rede compartilhada |
| `pods_ip_range_name` | `string` | — | Nome do range secundário de IPs de pods |
| `services_ip_range_name` | `string` | — | Nome do range secundário de IPs de serviços |
| `environment_size` | `string` | `"ENVIRONMENT_SIZE_SMALL"` | Tamanho do ambiente (`SMALL`/`MEDIUM`/`LARGE`) |
| `scheduler_cpu` / `scheduler_memory_gb` / `scheduler_storage_gb` / `scheduler_count` | `number` | `0.5` / `1.875` / `1` / `1` | Dimensionamento do scheduler |
| `triggerer_cpu` / `triggerer_memory_gb` / `triggerer_count` | `number` | `1` / `1` / `1` | Dimensionamento do triggerer |
| `web_server_cpu` / `web_server_memory_gb` / `web_server_storage_gb` | `number` | `0.5` / `2` / `1` | Dimensionamento do web server do Airflow |
| `worker_cpu` / `worker_memory_gb` / `worker_storage_gb` / `worker_min_count` / `worker_max_count` | `number` | `0.5` / `1.875` / `1` / `1` / `3` | Dimensionamento e autoscaling dos workers |
| `sa_roles` | `list(string)` | roles padrão de worker/BigQuery/Storage/Secret Manager | Roles concedidas à SA do ambiente no projeto de serviço |
| `airflow_config_overrides` | `map(string)` | `{}` | Overrides de configuração do Airflow |
| `pypi_packages` | `map(string)` | `{}` | Pacotes PyPI adicionais a instalar no ambiente |
| `enable_data_lineage` | `bool` | `false` | Habilita `cloud_data_lineage_integration` no software config |
| `kms_project_id` / `key_ring` / `key_crypto` | `string` | `null` | Projeto/keyring/chave KMS para criptografia do ambiente (opcional; se omitido, usa criptografia padrão do Google) |
| `maintenance_window` | `object({ start_time, end_time, recurrence })` | `null` | Janela de manutenção do ambiente (opcional) |
| `labels` | `map(string)` | `{}` | Labels aplicadas ao ambiente |

## Outputs

| Nome | Descrição |
|------|-----------|
| `composer_environment_names` | Nomes dos ambientes Composer criados, indexados pela chave do mapa |
| `composer_gcs_buckets` | Prefixo do bucket GCS de DAGs de cada ambiente |
| `composer_airflow_uris` | URLs da interface web do Airflow de cada ambiente |
| `composer_sa_emails` | E-mails das Service Accounts criadas para cada ambiente |
| `composer_sa_ids` | IDs únicos (`unique_id`) das Service Accounts, úteis para Workload Identity |
| `composer_environment_ids` | IDs completos dos recursos `google_composer_environment`, para referência entre módulos |

## Observações

- O nome do ambiente e da Service Account seguem o padrão `<chave-do-mapa>-<sigla>-<terraform.workspace>`: o módulo depende de `terraform.workspace` estar configurado corretamente (ex.: `dev`, `hml`, `prd`).
- A criptografia via KMS é opcional: só é aplicada (`encryption_config`) quando `key_ring` é informado; os data sources `google_kms_key_ring.composer`/`google_kms_crypto_key.composer` só são resolvidos nesse caso.
- Os bindings de KMS (`composer_sa_kms` e `composer_bucket_sa_kms`) são deduplicados em `locals.tf` por combinação de `project_id||kms_project_id||region||key_ring||key_crypto`, evitando conceder a mesma permissão duas vezes quando múltiplos ambientes compartilham a mesma chave.
- Todo ambiente recebe automaticamente `roles/bigquery.dataViewer` no projeto fixo `bigdata-1744049006` — um projeto corporativo de Big Data hardcoded no módulo, não parametrizável via variável.
- O bloco `lifecycle.ignore_changes` em `google_composer_environment` ignora mudanças em `ip_allocation_policy`, evitando recriações desnecessárias do ambiente.
- A criação do ambiente depende explicitamente (`depends_on`) dos bindings de IAM da Service Agent do Composer no projeto host, pois o Composer 3 precisa dessas permissões antes de conseguir provisionar recursos na Shared VPC.
- As variáveis `project_id` e `network_project_id` (fora do map) não têm `description` declarada no código.
