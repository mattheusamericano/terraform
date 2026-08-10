# spanner_database

Módulo que provisiona **databases Cloud Spanner** dentro de uma instância já existente, incluindo DDL inicial, CMEK (opcional) e bindings de IAM em nível de database. É o módulo "filho" na dupla [`spanner_instance`](../spanner_instance/README.md) + `spanner_database` — a instância é criada pelo outro módulo, e o nome real dela (`instance_name`) é passado para cá via output.

## Recursos criados

- `google_spanner_database.this` — o database Spanner. Nome final composto como `<chave>_<sigla>_<workspace>`. Suporta dialeto `GOOGLE_STANDARD_SQL` ou `POSTGRESQL`, DDL inicial, proteção contra deleção e período de retenção de versões. Bloco `encryption_config` dinâmico, criado apenas quando `encryption` é informado.
- `google_kms_crypto_key_iam_member.spanner_cmek` — concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` ao Service Agent do Spanner (`service-<PROJECT_NUMBER>@gcp-sa-spanner.iam.gserviceaccount.com`) em cada chave KMS referenciada em `encryption`, quando `grant_kms_iam = true`. Usa `_iam_member` (aditivo, não autoritativo) porque a policy da chave KMS pertence a um recurso/projeto externo ao Spanner.
- `google_spanner_database_iam_binding.database_admin` — binding autoritativo de `roles/spanner.databaseAdmin` no database, criado só se `iam_bindings.database_admins` não estiver vazio.
- `google_spanner_database_iam_binding.database_user` — binding autoritativo de `roles/spanner.databaseUser`.
- `google_spanner_database_iam_binding.database_reader` — binding autoritativo de `roles/spanner.databaseReader`.
- `data.google_project.spanner_project` — usado para obter o número do projeto (necessário para montar o e-mail do Service Agent do Spanner no binding de CMEK).

## Como usar

```hcl
module "spanner_database" {
  source = "./gcp/spanner_database"

  spanner_database_settings = {
    cache_decisao = {
      sigla         = "sipml"
      project_id    = "prj-sipml-gateway-prd"
      instance_name = module.spanner_instance.instance_names["hub_decision_broker"]

      database_dialect = "GOOGLE_STANDARD_SQL"
      ddl = [
        <<-EOT
        CREATE TABLE decision_cache (
          cache_key  STRING(MAX) NOT NULL,
          payload    JSON,
          created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
          expires_at TIMESTAMP
        ) PRIMARY KEY (cache_key)
        EOT
      ]

      deletion_protection      = true
      version_retention_period = "1h"

      encryption = {
        kms_key_name  = "projects/prj-kms/locations/southamerica-east1/keyRings/spanner-kr/cryptoKeys/spanner-key"
        grant_kms_iam = true
      }

      iam_bindings = {
        database_admins  = ["group:gcp-sipml-devops@caixa.gov.br"]
        database_users   = ["serviceAccount:decision-broker-run@prj-sipml-gateway-prd.iam.gserviceaccount.com"]
        database_readers = []
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `spanner_database_settings` | Mapa de configuração dos databases Spanner. Cada chave representa um database lógico dentro de uma instância. | `map(object({...}))` | — | Sim |

Campos do objeto (`spanner_database_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `sigla` | Sigla usada na composição do nome do database | `string` | — | Sim |
| `project_id` | Projeto onde a instância/database residem | `string` | — | Sim |
| `instance_name` | Nome real da instância (ex: `module.spanner_instance.instance_names["..."]`) | `string` | — | Sim |
| `database_dialect` | Dialeto do database: `GOOGLE_STANDARD_SQL` ou `POSTGRESQL` | `string` | `"GOOGLE_STANDARD_SQL"` | Não |
| `ddl` | Lista de statements DDL executadas na criação do database | `list(string)` | `[]` | Não |
| `deletion_protection` | Impede a deleção do database via Terraform enquanto `true` | `bool` | `true` | Não |
| `version_retention_period` | Período de retenção de versões antigas (ex: `"1h"`, `"7d"`) | `string` | `"1h"` | Não |
| `encryption.kms_key_name` | Chave KMS única, para instância regional. Preencher no máximo um entre `kms_key_name`/`kms_key_names` | `string` | `null` | Não |
| `encryption.kms_key_names` | Lista de chaves KMS (uma por região), para instância multi-região/custom | `list(string)` | `[]` | Não |
| `encryption.grant_kms_iam` | Se `true`, concede automaticamente `cryptoKeyEncrypterDecrypter` ao Service Agent do Spanner nas chaves informadas | `bool` | `true` | Não |
| `iam_bindings.database_admins` | Membros com `roles/spanner.databaseAdmin` no database | `list(string)` | `[]` | Não |
| `iam_bindings.database_users` | Membros com `roles/spanner.databaseUser` no database | `list(string)` | `[]` | Não |
| `iam_bindings.database_readers` | Membros com `roles/spanner.databaseReader` no database | `list(string)` | `[]` | Não |

## Outputs

Este módulo não possui `outputs.tf` — nenhum output é exposto atualmente.

## Observações

- **CMEK é imutável**: a configuração de `encryption` não pode ser alterada depois que o database é criado — o Spanner não permite trocar a chave KMS de um database existente.
- **`kms_key_name` x `kms_key_names`**: preencha apenas um dos dois. Se ambos forem informados, `kms_key_names` tem prioridade no bloco `encryption_config` (a lógica do local `cmek_key_bindings` prioriza `kms_key_names` quando não vazia).
- **Flatten para bindings de KMS**: como um database pode referenciar 0, 1 ou N chaves KMS, o binding de IAM na(s) chave(s) usa um `flatten()` (local `cmek_key_bindings`) em vez de um `for_each` direto sobre `spanner_database_settings` — mesmo padrão adotado no módulo de IAM do Dataplex.
- **Bindings de database são autoritativos**: os três `google_spanner_database_iam_binding` substituem todos os membros daquele papel no database a cada apply.
- **Dependência de ordem**: `instance_name` deve vir de uma instância já existente — normalmente o output `instance_names` do módulo `spanner_instance`.
- **DDL é placeholder**: o `example.tfvars` traz DDLs de exemplo genéricos (cache de decisão, log de auditoria) — ajuste para o schema real antes de aplicar em produção.
