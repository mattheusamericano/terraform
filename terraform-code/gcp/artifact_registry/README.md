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
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `artifact_registry_settings` | Mapa de configurações dos repositórios Artifact Registry a criar (sem `description` no código) | `map(object({...}))` | — | sim |

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

## Outputs

Este módulo não declara nenhum output (não há `outputs.tf`/`output.tf` no diretório).

## Observações

- O `repository_id` é montado como `<chave-do-mapa>-<sigla>-<terraform.workspace>`, portanto depende de `terraform.workspace` estar definido.
- Não há configuração de política de limpeza (`cleanup_policies`) além do flag `cleanup_policy_dry_run` — o módulo não define regras de retenção/expiração de artefatos.
- Não há IAM neste módulo: o acesso ao repositório deve ser gerenciado fora dele (ex.: via IAM de projeto ou outro módulo).
