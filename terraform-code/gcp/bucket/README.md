# bucket

Módulo Terraform para provisionar **buckets do Cloud Storage (GCS)** padronizados e seguros: acesso uniforme a nível de bucket, prevenção de acesso público, versionamento habilitado, expurgo automático de versões antigas arquivadas e criptografia obrigatória via Cloud KMS (CMEK). Assim como os demais módulos deste repositório, é orientado a `for_each` sobre um mapa de configurações.

## Recursos criados

- `google_storage_bucket.bucket` — o bucket GCS, com `name` derivado da chave do mapa, `uniform_bucket_level_access = true`, `public_access_prevention = "enforced"`, `force_destroy = true`, criptografia via `encryption.default_kms_key_name`, `versioning` habilitado e uma `lifecycle_rule` que apaga versões arquivadas quando já existe pelo menos uma versão mais nova.
- `google_kms_crypto_key_iam_member.gcs_kms_binding` — concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave KMS à Service Agent padrão do Cloud Storage do projeto (`service-<project-number>@gs-project-accounts.iam.gserviceaccount.com`), necessária para o bucket conseguir usar CMEK.
- `data.google_storage_project_service_account.gcs_sa` — resolve a Service Agent padrão do Cloud Storage de cada projeto usado.

## Como usar

```hcl
module "bucket" {
  source = "./gcp/bucket"

  bucket_settings = {
    dados-brutos = {
      project_id     = "prj-dados-dev"
      sigla          = "eng"
      region         = "southamerica-east1"
      storage_class  = "STANDARD"
      kms_project_id = "prj-kms-dev"
      kms_key_name   = "kr-gcs"
      kms_key_crypto = "key-gcs"

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
| `bucket_settings` | Mapa de configurações dos buckets GCS a criar (sem `description` no código) | `map(object({...}))` | — | sim |

### Estrutura de cada item de `bucket_settings`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde o bucket é criado |
| `sigla` | `string` | — | Sigla usada na composição do nome do bucket |
| `region` | `string` | — | Localização (`location`) do bucket |
| `storage_class` | `string` | — | Classe de armazenamento (ex.: `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`) |
| `kms_key_name` | `string` | — | Nome do keyring KMS usado na composição do `default_kms_key_name` |
| `kms_key_crypto` | `string` | — | Nome da chave KMS usada na criptografia CMEK do bucket |
| `kms_project_id` | `string` | — | Projeto onde vive a chave KMS |
| `labels` | `map(string)` | — | Labels aplicadas ao bucket |

Nenhum atributo é `optional()` nesta variável — todos são obrigatórios ao preencher cada item do mapa, incluindo os campos de KMS (criptografia customizada é sempre exigida por este módulo).

## Outputs

| Nome | Descrição |
|------|-----------|
| `bucket_names` | Nome de todos os buckets criados |
| `bucket_urls` | URLs (`gs://...`) de todos os buckets criados |
| `bucket_self_links` | Self-links dos buckets, úteis para uso em bindings de IAM |
| `bucket_locations` | Região de cada bucket |

## Observações

- Diferente de outros módulos do repositório (ex.: `bq_dataset`, `airflow_composer`), aqui a criptografia via KMS **não é opcional**: `kms_key_name`, `kms_key_crypto` e `kms_project_id` são campos obrigatórios do objeto, e o bloco `encryption` é sempre aplicado.
- A `lifecycle_rule` apaga (`Delete`) versões com `num_newer_versions = 1` e `with_state = "ARCHIVED"`, ou seja, mantém apenas uma versão mais recente antes de expurgar versões antigas já arquivadas — não há retenção por tempo (dias), apenas por contagem de versões.
- `force_destroy = true` e `delete` na lifecycle rule combinados significam que o módulo não protege contra perda de dados: destruir o módulo remove o bucket mesmo com objetos dentro, e versões antigas são apagadas automaticamente conforme novas versões surgem.
- O `public_access_prevention = "enforced"` bloqueia qualquer tentativa de tornar o bucket ou seus objetos públicos, independentemente de IAM configurado externamente.
- O nome final do bucket segue o padrão `<chave-do-mapa>-<sigla>-<terraform.workspace>`.
