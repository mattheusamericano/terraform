# dataform

Módulo Terraform para provisionar repositórios do **Dataform** integrados ao BigQuery, incluindo a service account dedicada usada pelo Dataform para executar as compilações/workflows e todo o conjunto de permissões IAM necessário para que essa service account opere corretamente (BigQuery, Secret Manager, Dataform e Storage).

## Recursos criados

- `google_service_account.dataform_sa` — cria a service account dedicada que o repositório Dataform usa para executar workspaces e workflows.
- `google_dataform_repository.repository` (via `repository.tf`, provider `google-beta`) — cria o repositório Dataform propriamente dito, associado à service account criada, com suporte opcional a integração com um repositório Git remoto.
- `google_project_iam_member.bq_data_editor` — concede `roles/bigquery.dataEditor` no projeto à service account do Dataform (leitura/escrita em tabelas).
- `google_project_iam_member.bq_job_user` — concede `roles/bigquery.jobUser` no projeto à service account (executar jobs de query).
- `google_project_iam_member.secret_accessor` — concede `roles/secretmanager.secretAccessor` no projeto à service account (acessar o token do Git armazenado no Secret Manager).
- `google_project_iam_member.dataform_editor` — concede `roles/dataform.editor` no projeto à service account (gerenciar workspaces e compilações).
- `google_project_iam_member.dataform_bucket_user` — concede `roles/storage.objectUser` no projeto à service account.
- `google_dataform_repository_iam_member.sa_repository_admin` (provider `google-beta`) — concede `roles/dataform.admin` diretamente no repositório criado à service account.
- `google_service_account_iam_member.dataform_sa_token_creator` — concede `roles/iam.serviceAccountTokenCreator` na service account do Dataform ao service agent da API do Dataform (`service-<project_number>@gcp-sa-dataform.iam.gserviceaccount.com`).
- `google_service_account_iam_member.dataform_sa_user` — concede `roles/iam.serviceAccountUser` na service account do Dataform ao mesmo service agent, permitindo que a API do Dataform impersonifique a SA para rodar os workflows.
- `google_project_iam_member.dataform_bigquery_viewer` — concede `roles/bigquery.dataViewer` no projeto fixo `bigdata-1744049006` à service account do Dataform (acesso de leitura a um projeto de Big Data compartilhado).

## Data sources utilizados

- `data.google_project.project` — resolve o número do projeto de cada configuração (`project_id`), usado para montar o e-mail do service agent do Dataform nos bindings de `google_service_account_iam_member`.

## Como usar

```hcl
module "dataform" {
  source = "./gcp/dataform"

  dataform_repository_settings = {
    "repo-analytics" = {
      project_id         = "meu-projeto-gcp"
      region             = "us-central1"
      sigla              = "dtf"
      service_account_id = "sa-dataform-analytics"
      git_url            = "https://github.com/minha-org/meu-repo-dataform.git"
      git_default_branch = "main"
      git_secret_version = "projects/meu-projeto-gcp/secrets/dataform-git-token/versions/latest"
      labels = {
        time = "engenharia-de-dados"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `dataform_repository_settings` | Mapa de repositórios Dataform a serem criados. `project_id` é o projeto onde o repositório e a service account são provisionados, `region` a localização do repositório, `sigla` um sufixo de nomenclatura, `service_account_id` o account ID da service account dedicada, `git_url`/`git_default_branch`/`git_secret_version` (opcionais) configuram a integração com um repositório Git remoto — só são aplicados se `git_url` for informado e não vazio — e `labels` os rótulos do repositório. | `map(object({ project_id = string, region = string, sigla = string, service_account_id = string, git_url = optional(string), git_default_branch = optional(string), git_secret_version = optional(string), labels = map(any) }))` | — | Sim |

## Outputs

Este módulo não define outputs.

## Observações

- Todo o módulo é orientado por `for_each` sobre `dataform_repository_settings`; cada chave do mapa gera um repositório, uma service account e o conjunto completo de bindings de IAM associados.
- O nome do repositório e da service account seguem o padrão `${chave}-${sigla}-${terraform.workspace}` (repositório) e o valor de `service_account_id` (SA).
- O bloco `git_remote_settings` do repositório só é criado (via `dynamic`) quando `git_url` está definido e não é vazio — caso contrário, o repositório é criado sem integração Git, operando apenas com workspaces internos do Dataform.
- `deletion_policy = "FORCE"` está fixo no repositório, ou seja, um `terraform destroy` remove o repositório mesmo que existam workspaces ou releases não commitados dentro dele.
- `workspace_compilation_overrides.default_database` é sempre definido como o próprio `project_id`, forçando as compilações do Dataform a usarem o projeto do repositório como banco padrão.
- Há um acoplamento explícito e não configurável a um projeto de Big Data fixo (`bigdata-1744049006`) através de `google_project_iam_member.dataform_bigquery_viewer` — todo repositório criado por este módulo recebe automaticamente `roles/bigquery.dataViewer` nesse projeto, independentemente do `project_id` informado.
- Os dois bindings sobre o service agent do Dataform (`dataform_sa_token_creator` e `dataform_sa_user`) são essenciais para que a API do Dataform consiga impersonificar a service account e executar workflows agendados; sem eles, execuções via workflow/release podem falhar por falta de permissão.
