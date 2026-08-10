# dataplex_knowledge_catalog_lake

Módulo Terraform para provisionar **Lakes** do Dataplex (`google_dataplex_lake`) — o contêiner de mais alto nível do Dataplex, que organiza zonas e assets de um domínio de dados — junto com os bindings de IAM que concedem acesso administrativo, de edição e de leitura a esses lakes via grupos do Google.

## Recursos criados

- `google_dataplex_lake.lake` — cria o Lake do Dataplex, com suporte opcional a integração com um serviço de Metastore (Dataproc Metastore) para catálogo Hive compartilhado, um para cada chave de `var.dataplex_lake_settings`.
- `google_dataplex_lake_iam_member.admin` — concede `roles/dataplex.admin` no lake ao grupo definido em `iam_groups.admin` (obrigatório, sempre provisionado).
- `google_dataplex_lake_iam_member.editor` — concede `roles/dataplex.editor` no lake ao grupo definido em `iam_groups.editor`, somente quando esse campo não é `null`.
- `google_dataplex_lake_iam_member.viewer` — concede `roles/dataplex.viewer` no lake ao grupo definido em `iam_groups.viewer`, somente quando esse campo não é `null`.

## Data sources utilizados

- `data.google_project.lake_projects` — resolve os projetos distintos referenciados em `dataplex_lake_settings` (deduplicados por `project_id`). Não é consumido por nenhum recurso do módulo hoje; serve como validação de que os projetos existem/são acessíveis.

## Como usar

```hcl
module "dataplex_knowledge_catalog_lake" {
  source = "./gcp/dataplex_knowledge_catalog_lake"

  dataplex_lake_settings = {
    "modelagem" = {
      project_id       = "meu-projeto-gcp"
      region           = "us-central1"
      sigla            = "dpx"
      lake_description = "Lake de dados de modelagem"
      labels = {
        dominio = "modelagem"
      }
      metastore_service = "projects/meu-projeto-gcp/locations/us-central1/services/metastore-compartilhado"

      iam_groups = {
        admin  = "grupo-admin-dataplex@empresa.com"
        editor = "grupo-editores-dados@empresa.com"
        viewer = null
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `dataplex_lake_settings` | Mapa de configurações dos Lakes Dataplex. Cada chave representa um domínio de dados (ex: `modelagem`, `inferencia`, `hub-features`). `project_id`/`region` localizam o lake, `sigla` um sufixo de nomenclatura, `lake_description` uma descrição livre (default: `"Lake gerenciado via Terraform"`), `labels` os rótulos do lake, `metastore_service` (opcional, default `null`) o caminho completo de um serviço de Dataproc Metastore para catálogo Hive compartilhado, e `iam_groups` um objeto com os grupos do Google que recebem acesso: `admin` (obrigatório), `editor` e `viewer` (opcionais — `null` significa que o binding correspondente não é provisionado). | `map(object({ project_id = string, region = string, sigla = string, lake_description = optional(string, "Lake gerenciado via Terraform"), labels = map(any), metastore_service = optional(string, null), iam_groups = object({ admin = string, editor = optional(string, null), viewer = optional(string, null) }) }))` | — | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| `ids` | IDs dos lakes criados, indexados por `lake_key` (chave do mapa). |
| `names` | Nomes dos lakes criados, indexados por `lake_key` — usado pelos módulos de zona (`dataplex_knowledge_catalog_zone`) e de asset/IAM que dependem do nome do lake já provisionado. |

## Observações

- O nome final do lake segue o padrão `lake-${chave}-${sigla}-${terraform.workspace}`; o `display_name` é gerado automaticamente em maiúsculas a partir da chave, sigla e workspace.
- O bloco `metastore` só é incluído no lake (via `dynamic`) quando `metastore_service` é diferente de `null` — sem esse campo, o lake é criado sem integração com um Metastore compartilhado.
- A estrutura `iam_groups` é o ponto mais importante para quem for consumir este módulo: `admin` é sempre obrigatório e sempre gera um binding; `editor` e `viewer` são opcionais e só geram bindings quando explicitamente preenchidos com um e-mail de grupo — deixá-los como `null` (o default) significa "não conceder este nível de acesso".
- Todos os bindings de IAM usam `member = "group:${...}"`, ou seja, os valores de `iam_groups.*` devem ser e-mails de **grupos do Google**, não de usuários individuais ou service accounts.
- Todo o módulo é orientado por `for_each` sobre `dataplex_lake_settings`; os bindings de `editor` e `viewer` usam um `for_each` filtrado (apenas as chaves cujo respectivo campo não é `null`), evitando a criação de bindings vazios ou inválidos.
- O output `names` é a interface esperada por módulos dependentes (zonas e assets do Dataplex), que resolvem o nome do lake pai a partir dele em vez de recebê-lo hardcoded.
