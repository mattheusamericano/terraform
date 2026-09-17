# artifact_registry

Módulo Terraform simples para provisionar repositórios **Artifact Registry** no GCP (ex.: imagens Docker, pacotes Maven/npm/Python, etc.), a partir de um mapa de configurações. Cada entrada do mapa gera um repositório independente, permitindo criar vários repositórios com uma única instância do módulo.

## Recursos criados

- `google_artifact_registry_repository.artifact_registry` — um repositório Artifact Registry por chave de `artifact_registry_settings`, com `repository_id` derivado da chave do mapa, formato, modo, localização, projeto, labels e política de limpeza (dry-run).

## Como usar

```hcl
module "artifact_registry" {
  source = "./gcp/artifact_registry"

  artifact_registry_settings = {
    imagens-app = {
      project_id             = "prj-dados-dev"
      region                 = "southamerica-east1"
      artifact_format        = "DOCKER"
      artifact_mode          = "STANDARD_REPOSITORY"
      cleanup_policy_dry_run = true
      sigla                  = "eng"
      labels = {
        squad = "engenharia-dados"
      }
    }

    # exemplo com CMEK
    imagens-app-cmek = {
      project_id             = "prj-dados-dev"
      region                 = "southamerica-east1"
      artifact_format        = "DOCKER"
      artifact_mode          = "STANDARD_REPOSITORY"
      cleanup_policy_dry_run = true
      sigla                  = "eng"
      labels = {
        squad = "engenharia-dados"
      }
      kms_project_id = "prj-hsm-services-prd"
      kms_key_ring   = "infrahsmPRDring"
      kms_crypto_key = "infraPRDSYMAES256hsm001"
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `artifact_registry_settings` | Mapa de configurações dos repositórios Artifact Registry a criar | `map(object({...}))` | — | sim |

### Estrutura de cada item de `artifact_registry_settings`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde o repositório é criado |
| `region` | `string` | — | Localização (`location`) do repositório |
| `artifact_format` | `string` | — | Formato do repositório (ex.: `DOCKER`, `MAVEN`, `NPM`, `PYTHON`) |
| `artifact_mode` | `string` | — | Modo do repositório (ex.: `STANDARD_REPOSITORY`, `REMOTE_REPOSITORY`, `VIRTUAL_REPOSITORY`) |
| `cleanup_policy_dry_run` | `bool` | `true` | Se `true`, as políticas de limpeza rodam em modo simulação, sem apagar artefatos |
| `sigla` | `string` | — | Sigla usada na composição do `repository_id` |
| `labels` | `map(any)` | — | Labels aplicadas ao repositório |
| `description` | `string` | `null` | Descrição livre do repositório (opcional) |
| `kms_project_id` | `string` | `null` | Projeto onde vive a chave CMEK (opcional — só necessário se for diferente de `project_id`) |
| `kms_key_ring` | `string` | `null` | Nome do key ring da chave CMEK (usa a mesma `region` do repositório como location da chave) |
| `kms_crypto_key` | `string` | `null` | Nome da crypto key CMEK |

## Outputs

| Nome | Descrição |
|------|-----------|
| `artifact_registry_repositories` | Mapa (mesma chave de `artifact_registry_settings`) com `id`, `name`, `repository_id`, `location`, `project`, `format`, `mode` e `kms_key_name` de cada repositório criado |

## Observações

- O `repository_id` é montado como `<chave-do-mapa>-<sigla>-<terraform.workspace>`, portanto depende de `terraform.workspace` estar definido.
- Não há configuração de política de limpeza (`cleanup_policies`) além do flag `cleanup_policy_dry_run` — o módulo não define regras de retenção/expiração de artefatos.
- Não há IAM neste módulo: o acesso ao repositório deve ser gerenciado fora dele (ex.: via IAM de projeto ou outro módulo).
- CMEK: o módulo monta o `kms_key_name` do repositório concatenando `kms_project_id`, `region` (reaproveitado como location da chave), `kms_key_ring` e `kms_crypto_key` (`local.artifact_registry_kms_key_names` em `main.tf`). Uma `validation` em `variables.tf` exige que `kms_project_id`, `kms_key_ring` e `kms_crypto_key` sejam preenchidos juntos (ou nenhum, e o repositório usa a chave gerenciada pelo Google). Como a chave sempre herda a mesma `region` do repositório, não é possível usar uma chave CMEK numa location diferente da do próprio repositório.
- CMEK também exige que a service account de serviço do Artifact Registry do projeto (`service-<PROJECT_NUMBER>@gcp-sa-artifactregistry.iam.gserviceaccount.com`) já tenha o papel `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave — o módulo não concede essa permissão, precisa ser feito fora dele (ex.: `google_kms_crypto_key_iam_member`).
