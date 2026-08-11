# iam_new

Versão redesenhada do módulo [`iam`](../iam/README.md), com uma responsabilidade única: **gerenciar custom roles de projeto e concessões de role (bindings)**. Este módulo **não cria Service Accounts nem nenhuma outra identidade** — cada recurso deste repositório já tem seu próprio dono para isso (ex.: o módulo [`service_account`](../service_account/README.md) para SAs genéricas, ou o `sa.tf`/`iam.tf` de cada módulo de recurso específico, como `airflow_composer`, `cloud_run`, `bq_dataset`, etc.). Misturar "criar identidade" com "conceder permissão" no mesmo módulo espalhava a mesma responsabilidade em vários lugares do repositório e acoplava o ciclo de vida da SA ao ciclo de vida da permissão sem necessidade.

Toda regra de negócio (quais grupos existem, quais roles cada um recebe, quais roles customizadas existem, quais SAs recebem o quê) é fornecida pelo stack que o consome (ex.: `arch-iam_new`), não pelo módulo em si.

## Por que um novo módulo em vez de alterar o `iam`

O módulo `iam` já está em uso e qualquer mudança de estrutura de recursos (renomear resource, remover `google_service_account`, etc.) força `terraform state mv`/recriação em produção. Criar `iam_new` como módulo à parte permite migrar stack por stack, no seu tempo. Veja "Como migrar" abaixo.

## O que mudou em relação ao `iam`

| Tema | `iam` (atual) | `iam_new` |
|---|---|---|
| Cria Service Account? | Sim (`google_service_account.sa`, a partir de `sa_settings`) | **Não.** Recebe e-mails de SAs já existentes como qualquer outro membro de `iam_bindings` |
| Projeto alvo | `var.iam_settings["iam"].project_id` (map com chave fixa obrigatória) | `var.project_id` (string simples) |
| Grupos/e-mails hardcoded | `G_GCP_RISCFAB_DTSC@corp.caixa.gov.br` fixo em 2 resources de `roles.tf` | Nenhum. Todo membro vem de `var.iam_bindings`, definido pelo stack |
| Custom roles | 5 `resource` fixos em `custom_roles.tf`, um por perfil | `for_each` genérico sobre `var.custom_roles` — adicionar/remover um perfil não toca código do módulo |
| Grants (para SAs, grupos ou usuários) | 4 arquivos diferentes (`composer.tf`, `globals.tf`, `roles.tf`, `iam_binging.tf`), mecanismos diferentes para SA x grupo | Um único mecanismo genérico: `var.iam_bindings` — não importa se o membro é uma SA, um grupo ou um usuário |
| Autoritativo x aditivo | Misturava `google_project_iam_member` (aditivo) e `google_project_iam_binding` (autoritativo) sem critério explícito por resource | Aditivo por padrão; autoritativo só se `authoritative = true` for setado explicitamente por entrada |
| `main.tf` | Só continha código comentado (`CONSULTAR SE VAMOS DAR ESSE ACESSO`) | Removido — módulo não tem arquivos sem recurso ativo |
| Nome de arquivo | `iam_binging.tf` (typo) | N/A — bindings unificados em `iam_bindings.tf` |
| Validação de entrada | Nenhuma | `project_id` não pode ser vazio |

### Por que o padrão aditivo (`google_project_iam_member`) é mais seguro

`google_project_iam_binding` é **autoritativo**: a cada `apply`, ele substitui a lista *inteira* de membros daquela role pelo que está no Terraform. Se alguém for adicionado à role manualmente (ou por outro processo/squad) fora desse código, o próximo `apply` remove esse acesso silenciosamente. No módulo antigo isso era usado para as custom roles e para `roles/notebooks.runner` sem essa distinção ficar explícita no código. Em `iam_new`, `authoritative = true` é uma decisão visível e por entrada — o padrão é sempre o aditivo, que só adiciona/remove o membro específico daquele `resource`.

### Por que não criar Service Accounts aqui

Antes de existir este módulo, várias SAs de uso específico de um recurso (Composer, Cloud Run, BigQuery Dataset, etc.) já eram criadas dentro do próprio módulo daquele recurso (`airflow_composer/sa.tf`, `cloud_run/sa.tf`, `bq_dataset/sa.tf`, ...), e SAs de uso mais genérico tinham o módulo dedicado [`service_account`](../service_account). O módulo `iam` antigo duplicava esse papel para um punhado de SAs "de plataforma" (`sa-global`, `sa-comp`, etc.), criando uma segunda forma de fazer a mesma coisa dentro do repositório. `iam_new` elimina essa duplicidade: quem precisa de uma SA usa `service_account` (ou o `sa.tf` do módulo do recurso); `iam_new` só concede roles a quem já existe.

## O que **não** foi alterado (decisão deliberada)

As roles concedidas hoje (`roles/storage.admin`, `roles/bigquery.admin`, `roles/composer.admin`, etc.) continuam as mesmas do módulo `iam` — este módulo não reduz escopo de permissões por conta própria. Definir o escopo mínimo real (least privilege) para cada Service Account/grupo exige conhecimento do que cada perfil de fato usa em produção. Ver seção "Próximos passos sugeridos".

## Inputs

| Nome | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `project_id` | `string` | sim | Projeto GCP alvo de todos os recursos. |
| `custom_roles` | `map(object({ role_id, title, description = optional(string,""), permissions, stage = optional(string,"GA") }))` | não (default `{}`) | Custom roles de projeto. Chave = referência usada como `"custom:<chave>"` em `iam_bindings`. |
| `iam_bindings` | `map(object({ role, members, authoritative = optional(bool,false) }))` | não (default `{}`) | Concede uma role a uma lista de membros (grupos, usuários **ou Service Accounts já existentes**, no formato completo do GCP). Aditivo por padrão; `authoritative = true` usa `google_project_iam_binding`. |

## Outputs

| Nome | Descrição |
|---|---|
| `custom_role_ids` | Mapa `chave de custom_roles -> nome completo da role`. |

## Exemplo mínimo

```hcl
module "service_account" {
  source = "../service_account"

  sa_settings = {
    sa-global = { project_id = "meu-projeto-gcp", display_name = "SA Global" }
  }
}

module "iam" {
  source     = "../iam_new"
  project_id = "meu-projeto-gcp"

  custom_roles = {
    data_engineer = {
      role_id     = "ENG_DADOS"
      title       = "ENG_DADOS"
      permissions = ["bigquery.tables.get", "bigquery.tables.list"]
    }
  }

  iam_bindings = {
    global_bq_admin = {
      role    = "roles/bigquery.admin"
      members = ["serviceAccount:${module.service_account.service_account_emails["sa-global"]}"]
    }
    data_engineer_custom_role = {
      role    = "custom:data_engineer"
      members = ["group:g-data-engineers@empresa.com"]
    }
  }
}
```

## Como migrar de `iam` para `iam_new`

Não é um `s/iam/iam_new/` direto — além dos nomes internos dos `resource` mudarem (ex.: 5 `google_project_iam_custom_role` viraram 1 `for_each`), as Service Accounts que antes eram criadas dentro do módulo `iam` (`sa-global`, `sa-comp`, `sa-cr-acc`, `sa-lg-vw`, `sa-lg-wr`, `sa-lg-adm`, `sa-itg`, `sa-clrun`, `sa-dt-run`) passam a ser criadas pelo módulo `service_account`. Para migrar um stack sem recriar essas SAs (o que trocaria seus e-mails e quebraria qualquer coisa que dependa deles fora do Terraform):

1. Gerar o `plan` do stack novo e usar `terraform state mv` para mover cada `google_service_account.sa["x"]` do state do módulo `iam` para o novo endereço em `module.service_account.google_service_account.sa["x"]`, antes do `apply`.
2. Fazer o mesmo para as custom roles (`google_project_iam_custom_role.*` → `module.iam.google_project_iam_custom_role.this["x"]`).
3. Em ambientes não produtivos, pode ser mais simples aceitar destroy/create.

## Próximos passos sugeridos (fora do escopo deste módulo)

- Revisar, com os donos de cada perfil (ML Engineer, Data Scientist, Data Engineer, SAs de sistema), se as roles amplas em nível de projeto (`storage.admin`, `bigquery.admin`, `composer.admin`, `logging.admin`) podem ser reduzidas a roles mais específicas ou escopadas por recurso (bucket/dataset) em vez de projeto inteiro.
- Revisar se o grupo antes hardcoded (`G_GCP_RISCFAB_DTSC@corp.caixa.gov.br`) ainda deve receber os acessos que tinha (`roles/aiplatform.admin`, `roles/iam.dataScientist`) e, se sim, declará-lo explicitamente em `iam_bindings` no `.tfvars`/`locals.tf` do stack, por ambiente.
- Revisar as listas de permissões das custom roles (`ENG_VIEWER`, `ENG_MLOPS`, `ENG_DADOS`, `CIENTISTA_DADOS`) — várias parecem ser cópias quase integrais de APIs inteiras do GCP; vale um exercício de "o que este perfil realmente usa hoje" para reduzir superfície de acesso.
