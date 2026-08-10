# cloud_sql_database

Módulo Terraform responsável por criar bancos de dados (`google_sql_database`) dentro de instâncias Cloud SQL **já existentes**. Ele não provisiona a instância em si — apenas resolve a instância via data source e cria um ou mais databases dentro dela, permitindo padronizar nomenclatura e centralizar a criação de múltiplos bancos a partir de um único mapa de configuração.

## Recursos criados

- `google_sql_database.databases` — cria o database dentro da instância Cloud SQL indicada, um para cada chave do mapa `var.cloud_sql_database_settings`.

## Data sources utilizados

- `data.google_sql_database_instance.instance` — resolve a instância Cloud SQL existente (por nome e projeto) onde cada database será criado.

## Como usar

```hcl
module "cloud_sql_database" {
  source = "./gcp/cloud_sql_database"

  cloud_sql_database_settings = {
    "app-db" = {
      project_id    = "meu-projeto-gcp"
      sigla         = "sqa"
      instance_name = "instancia-cloud-sql-prd"
      labels = {
        ambiente = "producao"
      }
    }
    "analytics-db" = {
      project_id    = "meu-projeto-gcp"
      sigla         = "sqa"
      instance_name = "instancia-cloud-sql-prd"
      labels = {
        ambiente = "producao"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `cloud_sql_database_settings` | Mapa de databases a serem criados. A chave do mapa é usada como parte do nome do database. `project_id` é o projeto onde a instância Cloud SQL existe, `sigla` é um sufixo de nomenclatura, `instance_name` é o nome da instância Cloud SQL alvo e `labels` são rótulos livres associados à configuração (não aplicados diretamente ao recurso, pois `google_sql_database` não suporta labels). | `map(object({ project_id = string, sigla = string, labels = map(any), instance_name = string }))` | — | Sim |

## Outputs

Este módulo não define outputs.

## Observações

- O nome final de cada database segue o padrão `${chave}-${sigla}-${terraform.workspace}`, garantindo unicidade entre workspaces (ex.: dev/hml/prd).
- A instância Cloud SQL referenciada em `instance_name` precisa já existir — o módulo apenas consulta (`data`), não cria a instância.
- Todo o módulo é orientado por `for_each` sobre `cloud_sql_database_settings`, então múltiplos databases (inclusive em instâncias diferentes) podem ser criados em uma única aplicação.
- O campo `labels` está declarado na variável mas não é utilizado em nenhum recurso do módulo (o recurso `google_sql_database` não possui suporte a labels no provider).
