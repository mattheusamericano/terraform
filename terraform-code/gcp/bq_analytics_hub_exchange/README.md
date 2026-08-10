# bq_analytics_hub_exchange

Módulo Terraform para provisionar **Data Exchanges do BigQuery Analytics Hub**, o mecanismo do GCP para publicar e compartilhar datasets do BigQuery (listings) entre times, projetos ou organizações. O módulo cria um Exchange por chave do mapa `analytics_hub_settings` e concede o papel de administrador do Exchange a um grupo do Google.

## Recursos criados

- `google_bigquery_analytics_hub_data_exchange.exchange` — o Data Exchange em si, com `data_exchange_id` derivado da chave do mapa, `display_name`/`description` customizáveis e `discovery_type` fixo em `DISCOVERY_TYPE_PUBLIC`. O bloco `sharing_environment_config` alterna dinamicamente entre `default_exchange_config` (exchange comum) e `dcr_exchange_config` (Data Clean Room), conforme `is_data_clean_room`.
- `google_bigquery_analytics_hub_data_exchange_iam_member.admin` — concede `roles/analyticshub.admin` ao grupo definido em `iam_groups.admin` para cada Exchange criado.
- `data.google_project.exchange_projects` — resolve os projetos únicos referenciados em `analytics_hub_settings` (deduplicados por `project_id`).

## Como usar

```hcl
module "bq_analytics_hub_exchange" {
  source = "./gcp/bq_analytics_hub_exchange"

  analytics_hub_settings = {
    dados-compartilhados = {
      project_id   = "prj-dados-dev"
      region       = "southamerica-east1"
      sigla        = "eng"
      display_name = "Exchange de Dados Compartilhados"
      description  = "Exchange para compartilhamento de datasets entre squads"

      is_data_clean_room = false

      iam_groups = {
        admin      = "gcp-analytics-hub-admins@empresa.com"
        publisher  = "gcp-analytics-hub-publishers@empresa.com"
        subscriber = "gcp-analytics-hub-subscribers@empresa.com"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `analytics_hub_settings` | Mapa de configurações dos Data Exchanges do Analytics Hub | `map(object({...}))` | — | sim |

### Estrutura de cada item de `analytics_hub_settings`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde o Exchange é criado |
| `region` | `string` | — | Localização do Exchange |
| `sigla` | `string` | — | Sigla usada na composição do `data_exchange_id` |
| `display_name` | `string` | — | Nome de exibição do Exchange |
| `description` | `string` | `"Exchange gerenciado via Terraform"` | Descrição do Exchange |
| `is_data_clean_room` | `bool` | `false` | `true` = Exchange privado (Data Clean Room), acesso controlado por IAM; `false` = Exchange público/aberto, descobrível por qualquer usuário da organização |
| `iam_groups.admin` | `string` | — | Grupo do Google que recebe `roles/analyticshub.admin` no Exchange |
| `iam_groups.publisher` | `string` | `null` (opcional) | Grupo destinado a publishers (declarado na variável, mas sem binding de IAM criado no módulo atualmente) |
| `iam_groups.subscriber` | `string` | `null` (opcional) | Grupo destinado a subscribers (declarado na variável, mas sem binding de IAM criado no módulo atualmente) |

## Outputs

| Nome | Descrição |
|------|-----------|
| `exchange_ids` | IDs completos dos Data Exchanges criados, indexados pela chave do mapa |
| `exchange_names` | `data_exchange_id` de cada Exchange, útil para referenciar em outros módulos |

## Observações

- **`discovery_type` é fixo em `DISCOVERY_TYPE_PUBLIC`** no `main.tf`, independentemente do valor de `is_data_clean_room`. O flag `is_data_clean_room` só afeta o bloco `sharing_environment_config` (DCR vs. padrão) — ele não torna o Exchange privado do ponto de vista de descoberta.
- **`iam_groups.publisher` e `iam_groups.subscriber` existem na variável mas não possuem bindings de IAM implementados em `iam.tf`** — apenas `iam_groups.admin` recebe permissão (`roles/analyticshub.admin`). Se publishers/subscribers precisarem de acesso, os bindings correspondentes (ex.: `roles/analyticshub.publisher`, `roles/analyticshub.subscriber`) precisam ser adicionados ao módulo.
- O `data_exchange_id` é montado como `exchange_<chave-do-mapa-com-underscore>_<sigla>_<terraform.workspace>` (hífens da chave do mapa são convertidos em underscore).
