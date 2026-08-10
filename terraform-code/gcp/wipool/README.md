# wipool

Módulo Terraform responsável por provisionar Workload Identity Federation (WIF) no GCP para permitir que sistemas externos (por exemplo, GitHub Actions) se autentiquem no Google Cloud sem uso de chaves de Service Account estáticas. O módulo cria um Workload Identity Pool, um provider OIDC dentro desse pool, uma Service Account dedicada e o binding de IAM que autoriza as identidades externas (via `principalSet`) a impersonar essa Service Account.

## Recursos criados

- `google_iam_workload_identity_pool.identity_pool` — cria o Workload Identity Pool.
- `google_iam_workload_identity_pool_provider.identity_pool_provider` — cria o provider OIDC dentro do pool, apontando para o `issuer_uri` do provedor externo (ex.: GitHub Actions).
- `google_service_account.wipool_sa` — cria a Service Account que será impersonada pelas identidades externas autenticadas via WIF.
- `google_service_account_iam_binding.wipool_identity_binding` — concede à `principalSet` do pool (filtrada por `attribute.repository_owner`) a role `roles/iam.workloadIdentityUser` sobre a Service Account, permitindo a impersonação.

## Como usar

```hcl
module "wipool" {
  source = "./gcp/wipool"

  wipool_settings = {
    "wipool-github" = {
      project_id           = "meu-projeto-gcp"
      wipool_display_name  = "Wipool GitHub"
      wipool_provider_id   = "github-provider"
      wipool_issuer_uri    = "https://token.actions.githubusercontent.com"
      attribute_condition  = "attribute.repository_owner == \"minha-org-github\""
      repository_owner     = "minha-org-github"
      wipool_sa_account_id = "sa-wipool-git-sqa-prd"

      attribute_mapping = {
        "google.subject"             = "assertion.sub"
        "attribute.actor"            = "assertion.actor"
        "attribute.aud"              = "assertion.aud"
        "attribute.repository"       = "assertion.repository"
        "attribute.repository_owner" = "assertion.repository_owner"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `wipool_settings` | Mapa de configurações de Workload Identity Pools a serem criados. A chave do mapa é usada diretamente como `workload_identity_pool_id`. Ver estrutura detalhada abaixo. | `map(object({...}))` | — | Sim |

### Estrutura de `wipool_settings`

Cada entrada do mapa representa um Workload Identity Pool completo (pool + provider + SA + binding) e aceita os seguintes campos:

| Campo | Tipo | Default | Descrição |
|-------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde o pool, o provider e a Service Account serão criados. |
| `wipool_display_name` | `string` | — | Nome de exibição do pool e também do provider (usado em ambos). |
| `wipool_provider_id` | `string` | — | ID do provider OIDC dentro do pool. |
| `attribute_condition` | `string` | — | Condição CEL que restringe quais tokens externos são aceitos pelo provider (ex.: restringir por organização/dono do repositório). |
| `wipool_issuer_uri` | `string` | — | URL do emissor OIDC do provedor externo (ex.: `https://token.actions.githubusercontent.com` para GitHub Actions). |
| `repository_owner` | `string` | — | Dono do repositório (organização/usuário) usado para montar o `principalSet` autorizado a impersonar a Service Account. |
| `wipool_sa_account_id` | `string` | — | `account_id` da Service Account criada para ser impersonada pelas identidades externas. |
| `attribute_mapping` | `optional(map(string))` | `null` | Mapeamento de atributos do token OIDC externo para atributos do Google (ex.: `google.subject`, `attribute.repository`). |

## Outputs

| Nome | Descrição |
|------|-----------|
| `identity_pool_ids` | Mapa da chave de cada pool para o seu `workload_identity_pool_id`. |
| `identity_pool_names` | Mapa da chave de cada pool para o seu resource name completo. |
| `provider_names` | Mapa da chave de cada pool para o resource name completo do provider OIDC associado, útil para configurar a autenticação WIF em pipelines externos (ex.: `google-github-actions/auth`). |
| `sa_binding_etags` | Mapa da chave de cada pool para o etag do IAM binding da Service Account, útil para auditoria. |

## Observações

- O `workload_identity_pool_id` do pool é exatamente a chave usada no mapa `wipool_settings` (não há concatenação com sigla/workspace como em outros módulos deste repositório).
- O binding de IAM (`google_service_account_iam_binding.wipool_identity_binding`) autoriza um `principalSet` — ou seja, **qualquer identidade externa** que satisfaça `attribute.repository_owner == repository_owner` dentro do pool pode impersonar a Service Account, não apenas um repositório específico. Para restringir a repositórios individuais, use `attribute_condition` de forma mais granular (ex.: incluindo `attribute.repository`).
- O binding depende explicitamente do provider (`depends_on = [google_iam_workload_identity_pool_provider.identity_pool_provider]`), garantindo que o pool e o provider já existam antes de conceder a permissão de impersonação.
- Este módulo cria a Service Account (`google_service_account.wipool_sa`) mas não concede a ela nenhuma role de projeto (ex.: `roles/*` em `google_project_iam_member`) — apenas a permissão de ser impersonada via WIF. As roles necessárias para as ações que essa SA vai executar (deploy, leitura de bucket, etc.) devem ser concedidas fora deste módulo.
- Todo o módulo é orientado por `for_each` sobre `wipool_settings`, permitindo criar múltiplos pools/providers/SAs (inclusive para provedores ou repositórios diferentes) em uma única aplicação.
