# service_account

Módulo Terraform responsável por criar Service Accounts (`google_service_account`) genéricas no GCP a partir de um mapa de configuração. Ele padroniza a nomenclatura das contas com base na chave do mapa, na sigla do time/solução e no workspace do Terraform, permitindo criar múltiplas Service Accounts em um ou mais projetos em uma única aplicação. Segue o mesmo padrão `for_each` sobre mapa dos demais módulos deste repositório.

Este módulo cria **apenas a identidade**. Concessão de roles/bindings de IAM é responsabilidade do módulo [`iam_new`](../iam_new/README.md), que recebe o e-mail gerado aqui (via `service_account_emails`) e concede as permissões necessárias — mantendo o ciclo de vida da SA desacoplado do ciclo de vida das permissões.

## Recursos criados

- `google_service_account.sa` — cria uma Service Account para cada chave do mapa `var.sa_settings`.

## Como usar

```hcl
module "service_account" {
  source = "./gcp/service_account"

  sa_settings = {
    "sa-app" = {
      project_id   = "meu-projeto-gcp"
      sigla        = "eng"
      display_name = "Service Account da aplicação X"
      description  = "Usada pela aplicação X para acessar Cloud SQL e Pub/Sub"
    }
    "sa-etl" = {
      project_id = "meu-projeto-gcp"
      sigla      = "eng"
      # display_name e description ficam com o default
    }
  }
}

module "iam" {
  source     = "../iam_new"
  project_id = "meu-projeto-gcp"

  iam_bindings = {
    sa_app_bq_editor = {
      role    = "roles/bigquery.dataEditor"
      members = ["serviceAccount:${module.service_account.service_account_emails["sa-app"]}"]
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `sa_settings` | Mapa de Service Accounts a serem criadas. A chave do mapa é usada como parte do `account_id`. | `map(object({...}))` | — | sim |

### Estrutura de cada item de `sa_settings`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde a Service Account será criada |
| `sigla` | `string` | — | Sigla do time/solução, usada na composição do `account_id` |
| `display_name` | `string` | `"SA <chave> (<workspace>)"` | Nome de exibição da conta |
| `description` | `string` | `"Service Account gerenciada via Terraform"` | Descrição da conta |
| `disabled` | `bool` | `false` | Se `true`, cria a SA já desabilitada |

## Outputs

| Nome | Descrição |
|------|-----------|
| `service_account_emails` | E-mail de cada SA criada — usado para referenciar a conta em bindings de IAM (ex.: `iam_new`) ou em outros módulos |
| `service_account_names` | Nome completo do recurso (`projects/.../serviceAccounts/...`) de cada SA |
| `service_account_account_ids` | `account_id` (parte local do e-mail, antes do `@`) de cada SA |
| `service_account_unique_ids` | `unique_id` (identificador numérico estável do IAM) de cada SA |

## Observações

- O `account_id` final segue o padrão `${chave}-${sigla}-${terraform.workspace}`, consistente com a nomenclatura usada nos demais módulos do repositório (ex.: `bucket`, `bq_dataset`).
- **Breaking change de nomenclatura**: antes desta versão, o `account_id` era `${chave}-${project_id}-${terraform.workspace}` (sem `sigla`). Como `account_id` é imutável no GCP, qualquer stack que já tenha SAs aplicadas com esse módulo vai gerar `destroy`/`create` no próximo `plan` — o que troca o e-mail da conta e quebra qualquer binding de IAM ou integração externa que dependa do e-mail antigo. Antes de aplicar em um ambiente já provisionado, avalie `terraform state mv` para o novo endereço/nome, ou aceite a recriação em ambientes onde isso for seguro (ex.: dev).
- O módulo não cria nenhum binding de IAM, chave (key) ou papel (role) para as Service Accounts — apenas a identidade em si. A concessão de permissões é feita pelo módulo `iam_new`, usando o output `service_account_emails`.
- Todo o módulo é orientado por `for_each` sobre `sa_settings`, então múltiplas Service Accounts (inclusive em projetos diferentes) podem ser criadas em uma única aplicação.
