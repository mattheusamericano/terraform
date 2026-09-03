# service_account

Módulo Terraform responsável por criar Service Accounts (`google_service_account`) genéricas no GCP a partir de um mapa de configuração, e opcionalmente conceder roles de projeto a cada uma — no próprio projeto da SA e/ou em projetos diferentes (cross-project). Ele padroniza a nomenclatura das contas com base na chave do mapa, na sigla do time/solução e no workspace do Terraform, permitindo criar múltiplas Service Accounts — cada uma com seu próprio conjunto de roles — em um ou mais projetos em uma única aplicação. Segue o mesmo padrão `for_each` sobre mapa dos demais módulos deste repositório.

As roles de cada SA são concedidas via `google_project_iam_member` (aditivo).

## Recursos criados

- `google_service_account.sa` — cria uma Service Account para cada chave do mapa `var.sa_settings`.
- `google_project_iam_member.sa_roles` — concede, para cada SA, cada role listada em `sa_settings.<chave>.roles`, no `project_id` da própria SA. Zero, uma ou várias roles por SA, independentes entre si.
- `google_project_iam_member.sa_cross_project_roles` — concede, para cada SA, cada `{project_id, role}` listado em `sa_settings.<chave>.cross_project_roles`, no projeto informado em cada entrada (diferente do projeto da SA). Um resource por combinação SA+projeto+role.

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
      roles = [
        "roles/cloudsql.client",
        "roles/pubsub.publisher",
      ]
    }
    "sa-etl" = {
      project_id = "meu-projeto-gcp"
      sigla      = "eng"
      # display_name e description ficam com o default
      roles = [
        "roles/bigquery.jobUser",
        "roles/bigquery.dataEditor",
        "roles/storage.objectAdmin",
      ]
    }
    "sa-readonly" = {
      project_id = "meu-projeto-gcp"
      sigla      = "eng"
      # sem roles: só cria a identidade, sem nenhuma permissão de projeto
    }
    "sa-dataform" = {
      project_id = "prj-modelagem"
      sigla      = "eng"
      roles      = ["roles/dataform.editor"]

      # roles em projetos diferentes de prj-modelagem — um resource por
      # combinação de projeto+role, independente das roles "locais" acima
      cross_project_roles = [
        { project_id = "prj-hsm-services-prd", role = "roles/cloudkms.cryptoKeyEncrypterDecrypter" },
        { project_id = "prj-bigdata-compartilhado", role = "roles/bigquery.dataViewer" },
      ]
    }
  }
}
```

Cada entrada do mapa tem sua própria lista de `roles`/`cross_project_roles`, totalmente independente das demais — `sa-app` e `sa-etl` acima recebem permissões diferentes.

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
| `roles` | `list(string)` | `[]` | Roles de projeto concedidas a esta SA (`google_project_iam_member`, aditivo), sempre no `project_id` da própria SA |
| `cross_project_roles` | `list(object({ project_id = string, role = string }))` | `[]` | Roles concedidas a esta SA em projetos diferentes do `project_id` da SA — uma entrada por combinação de projeto+role. Quem roda o `apply` precisa já ter permissão de conceder IAM em cada `project_id` listado aqui |

## Outputs

| Nome | Descrição |
|------|-----------|
| `service_account_emails` | E-mail de cada SA criada — usado para referenciar a conta em bindings de IAM ou em outros módulos |
| `service_account_names` | Nome completo do recurso (`projects/.../serviceAccounts/...`) de cada SA |
| `service_account_account_ids` | `account_id` (parte local do e-mail, antes do `@`) de cada SA |
| `service_account_unique_ids` | `unique_id` (identificador numérico estável do IAM) de cada SA |

## Observações

- O `account_id` final segue o padrão `${chave}-${sigla}-${terraform.workspace}`, consistente com a nomenclatura usada nos demais módulos do repositório (ex.: `bucket`, `bq_dataset`).
- **Breaking change de nomenclatura**: antes desta versão, o `account_id` era `${chave}-${project_id}-${terraform.workspace}` (sem `sigla`). Como `account_id` é imutável no GCP, qualquer stack que já tenha SAs aplicadas com esse módulo vai gerar `destroy`/`create` no próximo `plan` — o que troca o e-mail da conta e quebra qualquer binding de IAM ou integração externa que dependa do e-mail antigo. Antes de aplicar em um ambiente já provisionado, avalie `terraform state mv` para o novo endereço/nome, ou aceite a recriação em ambientes onde isso for seguro (ex.: dev).
- O módulo concede roles via `google_project_iam_member` (aditivo): cada `apply` só adiciona/remove o binding específico daquela SA+role, sem afetar outros membros já concedidos naquela role por fora do Terraform. Não é possível fazer binding autoritativo nem custom role — para isso, use o `iam_new`.
- **Cross-project (`cross_project_roles`)**: pensado pro caso comum de uma SA precisar de uma role num projeto diferente do seu (ex.: uma SA de Dataform em `prj-modelagem` que precisa de `roles/cloudkms.cryptoKeyEncrypterDecrypter` num projeto central de KMS). É só mais um `google_project_iam_member`, aditivo igual `roles` — a única diferença é que o `project` do resource vem de cada entrada da lista, não de `sa_settings.<chave>.project_id`. Isso significa que a identidade que roda `terraform apply` precisa ter permissão de conceder IAM em CADA projeto listado em `cross_project_roles` — se o projeto alvo usa uma service account de deploy diferente, o `apply` desse `google_project_iam_member` especificamente vai falhar por permissão, mesmo que o resto do módulo passe.
- O módulo não cria chave (key) para as Service Accounts — apenas identidade e, opcionalmente, roles de projeto (locais e/ou cross-project).
- Todo o módulo é orientado por `for_each` sobre `sa_settings`, então múltiplas Service Accounts (inclusive em projetos diferentes, cada uma com suas próprias roles) podem ser criadas em uma única aplicação.
- Se duas SAs diferentes do mesmo `sa_settings` compartilharem o mesmo `project_id` e a mesma role, cada uma gera seu próprio `google_project_iam_member` (a chave do `for_each` é `<sa>-<role>` para `roles`, `<sa>-<project_id>-<role>` para `cross_project_roles`), então não há conflito nem sobrescrita entre elas.
