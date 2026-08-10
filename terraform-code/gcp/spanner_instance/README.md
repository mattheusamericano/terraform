# spanner_instance

Módulo que provisiona **instâncias Cloud Spanner** e os bindings de IAM em nível de instância (admin, database admin, viewer). É o módulo "pai" na dupla `spanner_instance` + [`spanner_database`](../spanner_database/README.md) — a instância é criada aqui, e os databases dentro dela são criados pelo módulo `spanner_database`, referenciando o nome real da instância via output.

## Recursos criados

- `google_spanner_instance.this` — a instância Cloud Spanner. Nome final composto como `<chave>_<sigla>_<workspace>`. Suporta configuração regional ou multi-região (`config`), capacidade em processing units e edição (`STANDARD`/`ENTERPRISE`/`ENTERPRISE_PLUS`).
- `google_spanner_instance_iam_binding.admin` — binding **autoritativo** do papel `roles/spanner.admin`, criado apenas para instâncias cuja lista `iam_bindings.admins` não está vazia.
- `google_spanner_instance_iam_binding.database_admin` — binding autoritativo do papel `roles/spanner.databaseAdmin` em nível de instância.
- `google_spanner_instance_iam_binding.viewer` — binding autoritativo do papel `roles/spanner.viewer`.

## Como usar

```hcl
module "spanner_instance" {
  source = "./gcp/spanner_instance"

  spanner_instance_settings = {
    hub_decision_broker = {
      sigla            = "sipml"
      project_id       = "prj-sipml-gateway-prd"
      config           = "regional-southamerica-east1" # ou "nam-eur-asia1" para multi-região
      processing_units = 1000                            # múltiplo de 100; 1000 PU = 1 node
      edition          = "STANDARD"
      labels = {
        camada = "hub"
        uso    = "decision-broker"
      }
      iam_bindings = {
        admins          = ["group:gcp-sipml-admins@caixa.gov.br"]
        database_admins = ["group:gcp-sipml-devops@caixa.gov.br"]
        viewers         = []
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `spanner_instance_settings` | Mapa de configuração das instâncias Spanner. Cada chave representa uma instância lógica. | `map(object({...}))` | — | Sim |

Campos do objeto (`spanner_instance_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `sigla` | Sigla usada na composição do nome da instância | `string` | — | Sim |
| `project_id` | Projeto onde a instância será criada | `string` | — | Sim |
| `config` | Configuração de região/multi-região da instância (ex: `regional-southamerica-east1`) | `string` | — | Sim |
| `display_name` | Nome de exibição da instância; se omitido, usa `<chave>-<sigla>-<workspace>` | `string` | `null` (calculado via `coalesce`) | Não |
| `processing_units` | Capacidade de processamento, em múltiplos de 100 (1000 PU = 1 node) | `number` | `1000` | Não |
| `edition` | Edição da instância: `STANDARD`, `ENTERPRISE` ou `ENTERPRISE_PLUS` | `string` | `"STANDARD"` | Não |
| `labels` | Labels aplicadas à instância | `map(string)` | `{}` | Não |
| `iam_bindings.admins` | Membros com `roles/spanner.admin` na instância | `list(string)` | `[]` | Não |
| `iam_bindings.database_admins` | Membros com `roles/spanner.databaseAdmin` na instância | `list(string)` | `[]` | Não |
| `iam_bindings.viewers` | Membros com `roles/spanner.viewer` na instância | `list(string)` | `[]` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `instance_names` | Mapa chave => nome real da instância. Usado para encadear com o módulo `spanner_database` (`instance_name`) |
| `instance_ids` | Mapa chave => ID completo da instância |
| `instance_configs` | Mapa chave => `config` (região/multi-região) usada |

## Observações

- **Bindings são autoritativos**: os três `google_spanner_instance_iam_binding` substituem **todos** os membros daquele papel na instância a cada apply — qualquer membro concedido fora do Terraform nesses papéis será removido. Se precisar de bindings aditivos, é necessário trocar para `google_spanner_instance_iam_member`, o que exige um padrão de flatten (instância × membro), igual ao usado no módulo de IAM do Dataplex — comentário deixado no próprio `iam.tf`.
- **Encadeamento com `spanner_database`**: o nome real da instância (`instance_names`) deve ser passado como `instance_name` para o módulo `spanner_database`, já que o database não pode ser criado sem a instância existir primeiro.
- **`processing_units` vs nodes**: 1000 processing units equivalem a 1 node; o valor deve ser múltiplo de 100.
- Veja `example.tfvars` no diretório do módulo para um exemplo completo de `tfvars`.
