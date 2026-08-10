# service_account

Módulo Terraform responsável por criar Service Accounts (`google_service_account`) no GCP a partir de um mapa de configuração. Ele padroniza a nomenclatura das contas com base na chave do mapa, no projeto e no workspace do Terraform, permitindo criar múltiplas Service Accounts em um ou mais projetos em uma única aplicação.

## Recursos criados

- `google_service_account.sa` — cria uma Service Account para cada chave do mapa `var.sa_settings`.

## Como usar

```hcl
module "service_account" {
  source = "./gcp/service_account"

  sa_settings = {
    "sa-app" = {
      project_id   = "meu-projeto-gcp"
      display_name = "Service Account da aplicação X"
    }
    "sa-etl" = {
      project_id   = "meu-projeto-gcp"
      display_name = "Service Account do pipeline de ETL"
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `sa_settings` | Mapa de Service Accounts a serem criadas. A chave do mapa é usada como parte do `account_id` da conta. `project_id` é o projeto onde a Service Account será criada e `display_name` é o nome de exibição da conta. | `map(object({ project_id = string, display_name = string }))` | — | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| `service_account_emails` | Mapa da chave de cada Service Account (definida em `sa_settings`) para o e-mail gerado (`v.email`), útil para referenciar a conta em bindings de IAM ou em outros módulos. |

## Observações

- O `account_id` final de cada Service Account segue o padrão `${chave}-${project_id}-${terraform.workspace}`, garantindo unicidade entre workspaces (ex.: dev/hml/prd) e entre projetos.
- O módulo não cria nenhum binding de IAM, chave (key) ou papel (role) para as Service Accounts — apenas a identidade em si. A concessão de permissões deve ser feita por outro módulo/recurso (ex.: `google_project_iam_member`), utilizando o output `service_account_emails`.
- Todo o módulo é orientado por `for_each` sobre `sa_settings`, então múltiplas Service Accounts (inclusive em projetos diferentes) podem ser criadas em uma única aplicação.
