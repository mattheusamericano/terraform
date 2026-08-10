# firestore

Módulo Terraform para provisionar **databases do Cloud Firestore** no GCP, incluindo criptografia opcional com CMEK (Cloud KMS) e permissões de leitura/escrita via grupos do Google. Suporta a criação de múltiplos databases em um ou mais projetos através de um único mapa de configuração.

## Recursos criados

- `google_firestore_database.database` — cria o database do Firestore (`FIRESTORE_NATIVE` ou `DATASTORE_MODE`), com nome composto (`<chave>-<sigla>-<workspace>`), modo de concorrência, edição do database e point-in-time recovery variando conforme o workspace do Terraform (`prd` vs demais), e criptografia CMEK opcional via bloco dinâmico `cmek_config`.
- `google_kms_crypto_key_iam_member.firestore_sa_kms` — concede ao service agent do Firestore (`service-<project_number>@gcp-sa-firestore.iam.gserviceaccount.com`) a role `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave KMS, apenas quando `kms_keyring` está definido.
- `google_project_iam_member.firestore_writer` — concede `roles/datastore.user` ao grupo definido em `group_writer`.
- `google_project_iam_member.reader` — concede `roles/datastore.viewer` ao grupo definido em `group_reader`, apenas quando esse grupo é informado.

### Data sources utilizados

- `google_project.project` — resolve o número do projeto (necessário para montar o e-mail do service agent do Firestore).
- `google_kms_key_ring.keyring` — resolve o keyring existente, apenas para databases com KMS configurado.
- `google_kms_crypto_key.firestore_key` — resolve a chave de criptografia existente dentro do keyring, apenas para databases com KMS configurado.

## Como usar

```hcl
module "firestore" {
  source = "./gcp/firestore"

  firestore_settings = {
    app-principal = {
      project_id     = "meu-projeto-gcp"
      region         = "us-central1"
      sigla          = "app"
      type           = "FIRESTORE_NATIVE"
      group_writer   = "g-firestore-writers@empresa.com"
      group_reader   = "g-firestore-readers@empresa.com"
      kms_project_id = "meu-projeto-kms"
      kms_keyring    = "keyring-firestore"
      kms_crypto     = "chave-firestore"
      labels = {
        ambiente = "prd"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `firestore_settings` | Mapa de databases do Firestore a serem criados. | `map(object({ project_id=string, region=string, sigla=string, type=optional(string,"FIRESTORE_NATIVE"), kms_project_id=optional(string,null), kms_keyring=optional(string,null), kms_crypto=optional(string,null), group_writer=string, group_reader=optional(string), labels=map(any) }))` | — | sim |

### Estrutura de `firestore_settings`

Cada entrada do mapa representa um database e deve conter:

- `project_id` — projeto onde o database será criado.
- `region` — região (`location_id`) do database.
- `sigla` — sigla usada na composição do nome do database.
- `type` (opcional, default `FIRESTORE_NATIVE`) — modo do database (`FIRESTORE_NATIVE` ou `DATASTORE_MODE`).
- `kms_project_id`, `kms_keyring`, `kms_crypto` (opcionais, default `null`) — quando todos informados, habilitam CMEK: o keyring é lido em `kms_project_id`/`region`, a chave é lida dentro dele, e a permissão de uso é concedida ao service agent do Firestore.
- `group_writer` — grupo do Google que recebe `roles/datastore.user` (escrita).
- `group_reader` (opcional) — grupo do Google que recebe `roles/datastore.viewer` (leitura); se omitido, nenhuma permissão de leitura extra é criada.
- `labels` — labels do database (obrigatório, tipo `map(any)`).

## Outputs

| Nome | Descrição |
|------|-----------|
| `database_names` | Nomes dos databases criados, indexados pela chave do mapa. |
| `database_ids` | IDs dos databases criados, indexados pela chave do mapa. |

## Observações

- O nome do database é gerado automaticamente como `<chave>-<sigla>-<terraform.workspace>` — o módulo depende do uso de workspaces do Terraform para diferenciar ambientes.
- Comportamentos que variam por workspace (`terraform.workspace == "prd"`):
  - `concurrency_mode`: `OPTIMISTIC` em produção, `PESSIMISTIC` nos demais ambientes.
  - `database_edition`: aplicável apenas quando `type = "FIRESTORE_NATIVE"` — `ENTERPRISE` em produção, `STANDARD` nos demais (fica `null` para `DATASTORE_MODE`).
  - `point_in_time_recovery_enablement`: habilitado apenas em produção.
- `delete_protection_state` está fixo como `DELETE_PROTECTION_DISABLED` e `deletion_policy` como `DELETE` — isso é proposital para permitir que a esteira de CI/CD gerencie o ciclo de vida do recurso fim a fim (comentário explícito no código), mas significa que o database pode ser destruído sem proteção adicional do provider.
- CMEK é totalmente opcional: só é ativado quando `kms_keyring` (e correlatos) é diferente de `null`, via `for_each` filtrado nas data sources e no `dynamic "cmek_config"`.
- As permissões de IAM concedidas são no nível de **projeto** (`google_project_iam_member`), não no nível do database — portanto o grupo `group_writer`/`group_reader` recebe acesso a todos os recursos Datastore/Firestore do projeto, não apenas ao database criado por essa entrada.
