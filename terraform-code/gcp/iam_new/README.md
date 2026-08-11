# iam_new

Versão redesenhada do módulo [`iam`](../iam/README.md), focada em dois pontos: **remover dados específicos de negócio (grupos, e-mails, nomes de role) de dentro do código do módulo** e **tornar o padrão de concessão de permissões seguro por padrão**. Este módulo é 100% genérico — toda regra de negócio (quais grupos existem, quais roles cada um recebe, quais roles customizadas existem) é fornecida pelo stack que o consome (ex.: `arch-iam_new`), não pelo módulo em si.

## Por que um novo módulo em vez de alterar o `iam`

O módulo `iam` já está em uso e qualquer mudança de estrutura de recursos (renomear resource, trocar `for_each` por chave fixa, etc.) força `terraform state mv`/recriação em produção. Criar `iam_new` como módulo à parte permite migrar stack por stack, no seu tempo, sem risco de destruir/recriar Service Accounts ou custom roles existentes. Veja "Como migrar" abaixo.

## O que mudou em relação ao `iam`

| Tema | `iam` (atual) | `iam_new` |
|---|---|---|
| Projeto alvo | `var.iam_settings["iam"].project_id` (map com chave fixa obrigatória) | `var.project_id` (string simples) |
| Grupos/e-mails hardcoded | `G_GCP_RISCFAB_DTSC@corp.caixa.gov.br` fixo em 2 resources de `roles.tf` | Nenhum. Todo membro vem de `var.iam_bindings`, definido pelo stack |
| Custom roles | 5 `resource` fixos em `custom_roles.tf`, um por perfil | `for_each` genérico sobre `var.custom_roles` — adicionar/remover um perfil não toca código do módulo |
| Grants para Service Accounts | 3 arquivos (`composer.tf`, `globals.tf`, parte de `roles.tf`), um `resource` por grupo de permissões | Um único `for_each` genérico sobre `var.sa_role_bindings` |
| Grants para grupos/usuários | Misturava `google_project_iam_member` (aditivo) e `google_project_iam_binding` (autoritativo) sem critério explícito por resource | `var.iam_bindings` é aditivo (`_member`) por padrão; autoritativo (`_binding`) só se `authoritative = true` for setado explicitamente por entrada |
| `main.tf` | Só continha código comentado (`CONSULTAR SE VAMOS DAR ESSE ACESSO`) | Removido — módulo não tem arquivos sem recurso ativo |
| Nome de arquivo | `iam_binging.tf` (typo) | N/A — bindings unificados em `iam_bindings.tf` |
| `project_id` por SA | Obrigatório em cada entrada de `sa_settings`, sempre repetindo o mesmo valor | Opcional por SA (`optional(string)`); usa `var.project_id` se omitido |
| Validação de entrada | Nenhuma | `project_id` não pode ser vazio; `account_id` de cada SA é validado contra o formato aceito pelo GCP |

### Por que o padrão aditivo (`google_project_iam_member`) é mais seguro

`google_project_iam_binding` é **autoritativo**: a cada `apply`, ele substitui a lista *inteira* de membros daquela role pelo que está no Terraform. Se alguém for adicionado à role manualmente (ou por outro processo/squad) fora desse código, o próximo `apply` remove esse acesso silenciosamente — e o inverso, se alguém remover uma role via `iam_bindings` sem perceber que ela é a única fonte de verdade daquela role autoritativa, todos os membros somem de uma vez. No módulo antigo isso era usado para as custom roles e para `roles/notebooks.runner` sem essa distinção ficar explícita no código. Em `iam_new`, `authoritative = true` é uma decisão visível e por entrada — o padrão é sempre o aditivo, que só adiciona/remove o membro específico daquele `resource`.

## O que **não** foi alterado (decisão deliberada)

As roles concedidas hoje (`roles/storage.admin`, `roles/bigquery.admin`, `roles/composer.admin`, etc.) continuam as mesmas do módulo `iam` — este módulo não reduz escopo de permissões por conta própria. Definir o escopo mínimo real (least privilege) para cada Service Account/grupo exige conhecimento do que cada perfil de fato usa em produção, e isso é uma decisão de negócio, não algo que dá para inferir só lendo o código. Ver seção "Próximos passos sugeridos".

## Inputs

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `project_id` | `string` | sim | Projeto GCP alvo de todos os recursos. |
| `sa_settings` | `map(object({ display_name, sigla, project_id = optional(string) }))` | não (default `{}`) | Service Accounts a criar. Chave = referência estável usada em `sa_role_bindings.sa_key`. |
| `custom_roles` | `map(object({ role_id, title, description = optional(string,""), permissions, stage = optional(string,"GA") }))` | não (default `{}`) | Custom roles de projeto. Chave = referência usada como `"custom:<chave>"` em `sa_role_bindings`/`iam_bindings`. |
| `sa_role_bindings` | `map(object({ sa_key, role }))` | não (default `{}`) | Concede uma role (`"roles/x"` ou `"custom:<chave>"`) a uma SA criada em `sa_settings`. Sempre aditivo. |
| `iam_bindings` | `map(object({ role, members, authoritative = optional(bool,false) }))` | não (default `{}`) | Concede uma role a uma lista de membros externos (grupos/usuários/SAs). Aditivo por padrão; `authoritative = true` usa `google_project_iam_binding`. |

## Outputs

| Nome | Descrição |
|---|---|
| `service_account_emails` | Mapa `chave de sa_settings -> e-mail`. |
| `service_account_ids` | Mapa `chave de sa_settings -> id completo`. |
| `custom_role_ids` | Mapa `chave de custom_roles -> nome completo da role`. |

## Exemplo mínimo

```hcl
module "iam" {
  source     = "./iam_new"
  project_id = "meu-projeto-gcp"

  sa_settings = {
    sa-global = { display_name = "SA Global", sigla = "plat" }
  }

  custom_roles = {
    data_engineer = {
      role_id     = "ENG_DADOS"
      title       = "ENG_DADOS"
      permissions = ["bigquery.tables.get", "bigquery.tables.list"]
    }
  }

  sa_role_bindings = {
    global_bq_admin = { sa_key = "sa-global", role = "roles/bigquery.admin" }
  }

  iam_bindings = {
    data_engineer_custom_role = {
      role    = "custom:data_engineer"
      members = ["group:g-data-engineers@empresa.com"]
    }
  }
}
```

## Como migrar de `iam` para `iam_new`

Não é um `s/iam/iam_new/` direto — os nomes internos dos `resource` mudaram (ex.: 5 `google_project_iam_custom_role` viraram 1 `for_each`), então um `terraform plan` ingênuo apontaria destroy+create de Service Accounts e custom roles existentes. Para migrar um stack sem downtime/recriação:

1. Trocar o `source` do módulo e remapear as variáveis para o novo formato (o stack `arch-iam_new` já é um exemplo completo disso).
2. Gerar o `plan` e usar `terraform state mv` para apontar os recursos existentes (`google_service_account.sa["x"]`, `google_project_iam_custom_role.*`) para os novos endereços antes do `apply`, ou
3. Em ambientes não produtivos, aceitar o destroy/create (Service Accounts recriadas trocam de `unique_id`/e-mail se o `account_id` mudar — aqui o `account_id` é mantido idêntico, então normalmente o Terraform reconhece como "in place" contanto que o `state mv` seja feito).

## Próximos passos sugeridos (fora do escopo deste módulo)

- Revisar, com os donos de cada perfil (ML Engineer, Data Scientist, Data Engineer, SAs de sistema), se as roles amplas em nível de projeto (`storage.admin`, `bigquery.admin`, `composer.admin`, `logging.admin`) podem ser reduzidas a roles mais específicas ou escopadas por recurso (bucket/dataset) em vez de projeto inteiro.
- Revisar se o grupo antes hardcoded (`G_GCP_RISCFAB_DTSC@corp.caixa.gov.br`) ainda deve receber os acessos que tinha (`roles/aiplatform.admin`, `roles/iam.dataScientist`) e, se sim, declará-lo explicitamente em `iam_bindings` no `.tfvars`/`locals.tf` do stack, por ambiente.
- Revisar as listas de permissões das custom roles (`ENG_VIEWER`, `ENG_MLOPS`, `ENG_DADOS`, `CIENTISTA_DADOS`) — várias parecem ser cópias quase integrais de APIs inteiras do GCP; vale um exercício de "o que este perfil realmente usa hoje" para reduzir superfície de acesso.
