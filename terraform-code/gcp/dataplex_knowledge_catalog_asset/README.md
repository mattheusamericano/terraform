# dataplex_knowledge_catalog_asset

Módulo Terraform para registrar **assets** no Dataplex (`google_dataplex_asset`), vinculando um recurso de dados já existente — um dataset do BigQuery ou um bucket do Cloud Storage — a uma zona dentro de um Lake do Dataplex, habilitando descoberta automática (discovery) e catalogação desse recurso.

## Recursos criados

- `google_dataplex_asset.asset` — registra um asset (BigQuery dataset ou GCS bucket) dentro de uma zona de um Lake do Dataplex, incluindo configuração de descoberta automática, um para cada chave de `var.dataplex_asset_settings`.

## Como usar

```hcl
module "dataplex_knowledge_catalog_asset" {
  source = "./gcp/dataplex_knowledge_catalog_asset"

  dataplex_asset_settings = {
    "modelagem__curated__vendas" = {
      lake_key            = "modelagem"
      zone_key            = "modelagem__curated"
      project_id          = "meu-projeto-gcp"
      region              = "us-central1"
      sigla               = "dpx"
      resource_type       = "BIGQUERY_DATASET"
      resource_name       = "projects/meu-projeto-gcp/datasets/vendas_curated"
      asset_description   = "Dataset curado de vendas"
      discovery_enabled   = true
      discovery_schedule  = "0 */6 * * *"
      labels = {
        dominio = "vendas"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `dataplex_asset_settings` | Mapa de assets a serem criados. Chave recomendada: `lake_key__asset_key`. `lake_key` identifica o Lake pai (usado para resolver o nome do lake), `zone_key` identifica a zona pai completa (`lake_key__zone_key`, usada para resolver o nome da zona), `project_id`/`region` localizam o asset, `sigla` um sufixo de nomenclatura, `resource_type` indica se o recurso vinculado é `BIGQUERY_DATASET` ou `STORAGE_BUCKET`, `resource_name` é o caminho completo do recurso (ex: `projects/P/datasets/D` ou `projects/P/buckets/B`), `asset_description` uma descrição livre (default: `"Asset gerenciado via Terraform"`), `discovery_enabled` habilita/desabilita a descoberta automática (default: `true`), `discovery_schedule` define o cron da descoberta (default: `null`) e `labels` os rótulos do asset (default: `{}`). | `map(object({ lake_key = string, zone_key = string, project_id = string, region = string, sigla = string, resource_type = string, resource_name = string, asset_description = optional(string, "Asset gerenciado via Terraform"), discovery_enabled = optional(bool, true), discovery_schedule = optional(string, null), labels = optional(map(string), {}) }))` | — | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| `ids` | IDs dos assets criados, indexados pela chave do mapa. |
| `names` | Nomes dos assets criados, indexados pela chave do mapa. |

## Observações

- Este módulo **não cria** o Lake nem a Zona do Dataplex — os campos `lake` e `dataplex_zone` do recurso são preenchidos diretamente com `lake_key` e `zone_key`, ou seja, o módulo espera receber as chaves/nomes já resolvidos de um Lake e de uma Zona existentes (tipicamente provisionados pelos módulos `dataplex_knowledge_catalog_lake` e de zona correspondente).
- O nome final do asset segue o padrão `asset-${chave}-${sigla}-${terraform.workspace}` e o `display_name` é gerado automaticamente a partir da chave (maiúsculo, com `-` substituído por espaço).
- Todo o módulo é orientado por `for_each` sobre `dataplex_asset_settings`, permitindo registrar múltiplos assets — inclusive em lakes/zonas diferentes — em uma única aplicação.
- `resource_type` deve ser exatamente `BIGQUERY_DATASET` ou `STORAGE_BUCKET`, conforme exigido pela API do Dataplex; `resource_name` deve corresponder ao caminho completo do recurso daquele tipo.
