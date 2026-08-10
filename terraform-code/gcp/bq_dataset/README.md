# bq_dataset

Módulo Terraform para provisionar **datasets do BigQuery**, cada um com sua própria Service Account dedicada, IAM de acesso (owner via SA, editor via grupo) e criptografia opcional via Cloud KMS. Assim como os demais módulos GCP deste repositório, é orientado a `for_each`: cada chave de `bq_dataset_settings` gera um dataset completo.

## Recursos criados

- `google_bigquery_dataset.dataset` — o dataset do BigQuery, com `dataset_id` derivado da chave do mapa, `delete_contents_on_destroy = true`, expiração padrão de tabelas/partições opcional, labels e criptografia KMS opcional (`default_encryption_configuration`).
- `google_service_account.bq_dataset_sa` — Service Account dedicada a cada dataset, usada como "dona" (owner) do recurso.
- `google_bigquery_dataset_iam_member.access_owner` — concede `roles/bigquery.dataOwner` no dataset à SA dedicada do próprio dataset.
- `google_bigquery_dataset_iam_member.access_writer` — concede `roles/bigquery.dataEditor` no dataset ao grupo definido em `group_writer`.
- `google_project_iam_member.bigquery_viewer` — concede `roles/bigquery.dataViewer` à SA do dataset no projeto fixo `bigdata-1744049006` (projeto corporativo de Big Data).
- `google_kms_crypto_key_iam_member.bq_sa_kms` — concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` à Service Agent de criptografia do BigQuery (`bq-<project-number>@bigquery-encryption.iam.gserviceaccount.com`) na chave KMS, uma vez por projeto único que usa KMS.
- `data.google_project.project` — resolve o número de cada projeto único que usa KMS.
- `data.google_kms_key_ring.keyring` / `data.google_kms_crypto_key.keycrypto` — resolvem o keyring/chave KMS de cada projeto único que usa KMS.

## Como usar

```hcl
module "bq_dataset" {
  source = "./gcp/bq_dataset"

  bq_dataset_settings = {
    vendas = {
      project_id   = "prj-dados-dev"
      sigla        = "eng"
      region       = "southamerica-east1"
      group_writer = "gcp-bq-vendas-writers@empresa.com"
      sa_name      = "bq-vendas"

      labels = {
        squad = "engenharia-dados"
      }
      description = "Dataset de dados de vendas"

      default_table_expiration_ms     = 7776000000 # 90 dias
      default_partition_expiration_ms = null

      kms_project_id = "prj-kms-dev"
      key_ring       = "kr-bigquery"
      key_crypto     = "key-bigquery"
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `bq_dataset_settings` | Mapa de configurações dos datasets do BigQuery a criar (sem `description` no código) | `map(object({...}))` | — | sim |

### Estrutura de cada item de `bq_dataset_settings`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde o dataset é criado |
| `sigla` | `string` | — | Sigla usada na composição do `dataset_id` |
| `region` | `string` | — | Localização do dataset |
| `group_writer` | `string` | — | Grupo do Google que recebe `roles/bigquery.dataEditor` no dataset |
| `sa_name` | `string` | — | Nome base usado na composição do `account_id` da SA do dataset |
| `labels` | `map(string)` | — | Labels aplicadas ao dataset |
| `description` | `string` | `"Dataset created by Terraform"` | Descrição do dataset |
| `default_table_expiration_ms` | `number` | `null` | Expiração padrão (ms) das tabelas do dataset |
| `default_partition_expiration_ms` | `number` | `null` | Expiração padrão (ms) das partições do dataset |
| `kms_project_id` | `string` | `null` | Projeto da chave KMS (usado para resolver o keyring via data source) |
| `key_ring` | `string` | `null` | Nome do keyring KMS (se informado, habilita criptografia customizada) |
| `key_crypto` | `string` | `null` | Nome da chave de criptografia KMS |
| `kms_key` | `string` | `null` | Declarada na variável, mas não utilizada em nenhum recurso do módulo atualmente |

## Outputs

| Nome | Descrição |
|------|-----------|
| `dataset_ids` | ID de cada dataset criado |
| `dataset_self_links` | Self-links dos datasets |
| `dataset_project_ids` | Projeto de cada dataset |
| `dataset_sa_emails` | E-mails das Service Accounts de cada dataset |

## Observações

- O `kms_key_name` aplicado ao dataset em `main.tf` é montado com o projeto **fixo `prj-hsm-services-des`** (`projects/prj-hsm-services-des/locations/.../keyRings/.../cryptoKeys/...`), e **não** com o valor da variável `kms_project_id` — mesmo essa variável existindo e sendo usada para resolver os data sources de KMS em `data.tf`. Ou seja, o projeto onde a chave KMS efetivamente vive (para fins do dataset) é sempre `prj-hsm-services-des`, independentemente do que for passado em `kms_project_id`. Vale revisar se isso é intencional antes de usar o módulo em um projeto de KMS diferente.
- A variável `kms_key` existe no schema de `bq_dataset_settings` mas não é referenciada em nenhum recurso — parece não utilizada.
- Os bindings de KMS (`bq_sa_kms`) são deduplicados por `project_id` em `locals.tf` (`distinct_projects_with_kms`), evitando conceder a mesma permissão duas vezes quando múltiplos datasets do mesmo projeto usam KMS.
- Todo dataset gera automaticamente uma SA dedicada que se torna `dataOwner` do próprio dataset e recebe `bigquery.dataViewer` no projeto corporativo fixo `bigdata-1744049006`.
- `delete_contents_on_destroy = true`: ao destruir o módulo, o conteúdo do dataset (tabelas, views, dados) é apagado junto — não há proteção contra perda acidental de dados.
