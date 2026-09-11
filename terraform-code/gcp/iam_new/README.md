# iam_new

Versão redesenhada do módulo [`iam`](../iam/README.md), com uma responsabilidade única: **conceder roles PREDEFINIDAS do GCP (bindings)**. Este módulo **não cria Service Accounts nem nenhuma outra identidade** — cada recurso deste repositório já tem seu próprio dono para isso (ex.: o módulo [`service_account`](../service_account/README.md) para SAs genéricas, ou o `sa.tf`/`iam.tf` de cada módulo de recurso específico, como `airflow_composer`, `cloud_run`, `bq_dataset`, etc.). Misturar "criar identidade" com "conceder permissão" no mesmo módulo espalhava a mesma responsabilidade em vários lugares do repositório e acoplava o ciclo de vida da SA ao ciclo de vida da permissão sem necessidade. Também **não cria custom roles** — só roles predefinidas do GCP (ver "Só roles predefinidas do GCP" abaixo).

Pelo mecanismo genérico `iam_bindings`, toda regra de negócio (quais grupos existem, quais roles cada um recebe) é fornecida pelo stack que o consome (ex.: `arch-iam_new`), não pelo módulo em si. A exceção deliberada é `ml_ops_profiles` (ver abaixo): ali é o módulo que fixa quais roles cada perfil (ML Engineer/Data Scientist/Data Engineer) recebe — o stack só informa quem (grupo) e qual o estágio do ambiente, nunca quais roles. Isso é intencional: evita que quem só edita `.tfvars`/o stack consiga mudar o que um perfil pode fazer.

## Por que um novo módulo em vez de alterar o `iam`

O módulo `iam` já está em uso e qualquer mudança de estrutura de recursos (renomear resource, remover `google_service_account`, etc.) força `terraform state mv`/recriação em produção. Criar `iam_new` como módulo à parte permite migrar stack por stack, no seu tempo. Veja "Como migrar" abaixo.

## O que mudou em relação ao `iam`

| Tema | `iam` (atual) | `iam_new` |
|---|---|---|
| Cria Service Account? | Sim (`google_service_account.sa`, a partir de `sa_settings`) | **Não.** Recebe e-mails de SAs já existentes como qualquer outro membro de `iam_bindings` |
| Projeto alvo | `var.iam_settings["iam"].project_id` (map com chave fixa obrigatória) | `var.project_id` (string simples) |
| Grupos/e-mails hardcoded | `G_GCP_RISCFAB_DTSC@corp.caixa.gov.br` fixo em 2 resources de `roles.tf` | Nenhum. Todo membro vem de `var.iam_bindings`, definido pelo stack |
| Custom roles | 5 `resource` fixos em `custom_roles.tf`, um por perfil | **Nenhuma.** `iam_new` só concede roles predefinidas do GCP — ver "Só roles predefinidas do GCP" abaixo |
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
| `iam_bindings` | `map(object({ role, members, authoritative = optional(bool,false) }))` | não (default `{}`) | Concede uma role PREDEFINIDA do GCP (`"roles/x"`) a uma lista de membros (grupos, usuários **ou Service Accounts já existentes**, no formato completo do GCP). Aditivo por padrão; `authoritative = true` usa `google_project_iam_binding`. |
| `dataform_service_agent` | `object({ enabled = optional(bool,false), execution_service_account_email = optional(string,null), kms_project_id = optional(string,null) })` | não (default `{}`, ou seja `enabled = false`) | Liga/desliga (por projeto) as permissões que o Dataform Service Agent precisa: impersonar a SA de execução do Dataform — `roles/iam.serviceAccountTokenCreator` + `roles/iam.serviceAccountUser`, concedidos **na própria SA** informada em `execution_service_account_email` (obrigatório quando `enabled = true`); Developer Connect — `roles/developerconnect.gitProxyUser` + `roles/developerconnect.tokenAccessor`, em `var.project_id`; e, se `kms_project_id` for informado, `roles/cloudkms.cryptoKeyEncrypterDecrypter` nesse projeto externo. |
| `ml_ops_profiles` | `object({ enabled = optional(bool,false), environment_type = optional(string,null), ml_engineer_org_group = optional(string,null), ml_data_scientist_org_group = optional(string,null), data_engineer_org_group = optional(string,null) })` | não (default `{}`, ou seja `enabled = false`) | Liga/desliga os 3 perfis organizacionais (ML Engineer, ML Data Scientist, Data Engineer) — ver seção dedicada abaixo. `environment_type` (`"nprod"` ou `"prod"`) é obrigatório quando `enabled = true`. Cada grupo (`*_org_group`, formato completo do GCP, ex.: `"group:x@dominio.com"`) é opcional — omitir um grupo só significa que aquele perfil não recebe nada neste projeto. |

## Outputs

| Nome | Descrição |
|---|---|
| `project_id` | Repassa `var.project_id` — útil para encadear outros módulos sem precisar redigitar o valor no stack. |
| `dataform_service_agent_member` | Identidade do Dataform Service Agent (`serviceAccount:service-<PROJECT_NUMBER>@gcp-sa-dataform.iam.gserviceaccount.com`) quando `dataform_service_agent.enabled = true`; `null` caso contrário. |
| `ml_ops_profile_roles` | Mapa `{ ml_engineer, ml_data_scientist, data_engineer } -> lista de roles` efetivamente concedidas, já resolvida pela trilha (`environment_type`). `null` quando `ml_ops_profiles.enabled = false`. Existe para quem precisa auditar/validar o acesso sem ler `ml_ops_profiles.tf`. |
| `ml_ops_group_role_bindings` | Mapa completo `"<perfil>-<role>" -> { role, member }` de todos os bindings de perfil ML Ops criados. `{}` quando `ml_ops_profiles.enabled = false`. |

## Exemplo mínimo

```hcl
module "service_account" {
  source = "../service_account"

  sa_settings = {
    sa-meuproduto = { project_id = "meu-projeto-gcp", display_name = "SA Meu Produto" }
  }
}

module "iam" {
  source     = "../iam_new"
  project_id = "meu-projeto-gcp"

  iam_bindings = {
    bq_admin = {
      role    = "roles/bigquery.admin"
      members = ["serviceAccount:${module.service_account.service_account_emails["sa-meuproduto"]}"]
    }
    data_engineer_reader = {
      role    = "roles/bigquery.dataViewer"
      members = ["group:g-data-engineers@empresa.com"]
    }
  }

  dataform_service_agent = {
    enabled                          = true
    execution_service_account_email  = "sa-df-meuproduto@meu-projeto-gcp.iam.gserviceaccount.com"
    kms_project_id                   = "prj-hsm-services-prd"
  }

  ml_ops_profiles = {
    enabled                      = true
    environment_type             = "prod" # ou "nprod"
    ml_engineer_org_group        = "group:g-ml-engineer@empresa.com"
    ml_data_scientist_org_group  = "group:g-ml-data-scientist@empresa.com"
    data_engineer_org_group      = "group:g-data-engineer@empresa.com"
  }
}
```

## Como migrar de `iam` para `iam_new`

Não é um `s/iam/iam_new/` direto — além de `iam_new` não criar mais nenhuma custom role (ver "Só roles predefinidas do GCP" abaixo; as 5 custom roles antigas, se ainda em uso em algum stack, precisam de plano de migração à parte), as Service Accounts que antes eram criadas dentro do módulo `iam` (`sa-global`, `sa-comp`, `sa-cr-acc`, `sa-lg-vw`, `sa-lg-wr`, `sa-lg-adm`, `sa-itg`, `sa-clrun`, `sa-dt-run`) passam a ser criadas pelo módulo `service_account`. Para migrar um stack sem recriar essas SAs (o que trocaria seus e-mails e quebraria qualquer coisa que dependa deles fora do Terraform):

1. Gerar o `plan` do stack novo e usar `terraform state mv` para mover cada `google_service_account.sa["x"]` do state do módulo `iam` para o novo endereço em `module.service_account.google_service_account.sa["x"]`, antes do `apply`.
2. Em ambientes não produtivos, pode ser mais simples aceitar destroy/create.

## `ml_ops_profiles` — perfis organizacionais, só roles predefinidas

Ao contrário de `iam_bindings` (genérico, regra de negócio vem do stack), `ml_ops_profiles` é uma feature opinativa: as listas de roles de cada perfil (ML Engineer, ML Data Scientist, Data Engineer), para as duas trilhas nprod/prod, são fixas neste módulo (`ml_ops_profiles.tf`). O stack só informa **quem** (e-mail de cada grupo) e **qual o estágio do ambiente** (`environment_type`) — nunca quais roles. `environment_type` é uma condição genérica (estágio do ambiente, não tipo de carga de trabalho do projeto) — não fica amarrada a "modelagem"/"inferência", cabendo em qualquer projeto. Essa divisão é deliberada: o técnico que edita o stack/`.tfvars` de um ambiente não deve poder, sem querer ou por engano, ampliar o acesso de um perfil — mudar o conjunto de roles é uma alteração de código neste módulo, revisável como qualquer PR.

- **`environment_type = "nprod"`**: cada perfil recebe seu conjunto completo de roles predefinidas.
- **`environment_type = "prod"`**: cada perfil é reduzido aos equivalentes "viewer" das mesmas roles (ex.: `roles/bigquery.dataEditor` → `roles/bigquery.dataViewer`).
- Cada grupo é independente: um projeto em ambiente `prod`, por exemplo, pode só ter `data_engineer_org_group` preenchido e deixar os outros dois `null` — não concede nada daqueles perfis, sem erro.

## Só roles predefinidas do GCP — nenhuma custom role

`iam_new` não cria custom roles — `iam_bindings` só aceita `"roles/x"` (role predefinida do GCP). Quem precisar de uma role customizada deve criá-la fora deste módulo (ex.: `google_project_iam_custom_role` diretamente no stack) e referenciá-la aqui pelo nome completo.

O módulo antigo (`iam`) criava 5 custom roles (`ENG_MLOPS`, `CIENTISTA_DADOS`, `ENG_DADOS`, `ENG_VIEWER` e mais uma genérica), cada uma com uma lista de 200 a 800+ permissões individuais — os perfis ML Ops de `iam_new` (ver acima) foram desenhados para substituir essas 4 primeiras por combinações de roles predefinidas, por dois motivos:
1. **Gestão/organização**: uma lista de permissões soltas é difícil de auditar; roles predefinidas são mantidas e documentadas pelo próprio Google, com escopo conhecido e estável.
2. **Superfície de acesso a IAM de outros recursos/contas**: as listas antigas incluíam bastante `getIamPolicy`/`setIamPolicy` — a de "ENG_VIEWER", apesar do nome, tinha **322 permissões de escrita** e **54 ocorrências de `getIamPolicy`/`setIamPolicy`** — além de permissões de impersonação de Service Account (`iam.serviceAccounts.actAs`, `signBlob`, `signJwt`, `getAccessToken`, `getOpenIdToken`, `implicitDelegation`). Nenhuma dessas permissões foi carregada para as roles predefinidas. Quem precisar impersonar uma SA específica recebe isso via binding **na própria SA** (ex.: `cross_project_roles` do módulo `service_account`, ou `dataform_service_agent` deste módulo), nunca uma permissão ampla de projeto concedida ao grupo inteiro. Pelo mesmo motivo, `roles/storage.admin` (que inclui `setIamPolicy`/`getIamPolicy` no bucket) foi trocada por `roles/storage.objectAdmin` em todo o módulo, não só onde vinha de custom role.

**Achado ao migrar**: `permissions_data_engineer.tf` (removido) era, byte a byte, uma cópia de `permissions_ml_engineer.tf` — bug de copy-paste anterior a esta mudança, a custom role ENG_DADOS nunca teve de fato uma lista própria. Por isso o perfil Data Engineer **não** recebe o bundle equivalente ao antigo ENG_MLOPS (Dataproc/Dataplex/Logging/Notebooks) — incluir isso propagaria o bug em vez de corrigi-lo. Data Engineer mantém só as roles que já eram genuinamente dele (BigQuery, Dataform, Composer, Dataproc worker, Storage, Logging, a persona `iam.mlEngineer`).

### Mapeamento completo por perfil (`ml_ops_profiles.tf`)

**ML Engineer**
| nprod | prod |
|---|---|
| `roles/dataproc.editor` | `roles/dataproc.viewer` |
| `roles/dataplex.catalogEditor` ⚠️ | `roles/dataplex.catalogViewer` ⚠️ |
| `roles/logging.admin` | `roles/logging.viewer` |
| `roles/notebooks.runner` | `roles/notebooks.viewer` ⚠️ |
| `roles/compute.viewer` | `roles/compute.viewer` |
| `roles/iap.httpsResourceAccessor` | `roles/iap.httpsResourceAccessor` (sem variante "viewer") |
| `roles/run.developer` | `roles/run.viewer` |
| `roles/aiplatform.viewer` | `roles/aiplatform.viewer` |
| `roles/iam.roleViewer` | `roles/iam.roleViewer` |
| `roles/cloudbuild.connectionAdmin` | *(removida — sem equivalente "viewer" documentado)* |

**ML Data Scientist**
| nprod | prod |
|---|---|
| `roles/aiplatform.user` | `roles/aiplatform.viewer` |
| `roles/notebooks.admin` | `roles/notebooks.viewer` ⚠️ |
| `roles/bigquery.dataEditor` | `roles/bigquery.dataViewer` |
| `roles/bigquery.jobUser` | *(removida — rodar query não é leitura)* |
| `roles/storage.objectAdmin` | `roles/storage.objectViewer` |
| `roles/artifactregistry.reader` | `roles/artifactregistry.reader` |
| `roles/cloudbuild.builds.editor` | *(removida — rodar build não é leitura)* |
| `roles/logging.viewer` | `roles/logging.viewer` |
| `roles/dataproc.editor` | `roles/dataproc.viewer` |
| `roles/serviceusage.serviceUsageViewer` | `roles/serviceusage.serviceUsageViewer` |
| `roles/iam.roleViewer` | `roles/iam.roleViewer` |
| `roles/iam.dataScientist` | `roles/iam.dataScientist` |

Descartadas da antiga custom role CIENTISTA_DADOS por serem permissões pontuais de baixo valor prático: Cloud KMS Autokey, Firebase, Gemini Cloud Assist, Org Policy, Recommender, Remote Build Execution — reavaliar com o time se alguma fizer falta.

**Data Engineer**
| nprod | prod |
|---|---|
| `roles/aiplatform.viewer` | `roles/aiplatform.viewer` |
| `roles/iam.roleViewer` | `roles/iam.roleViewer` |
| `roles/bigquery.dataEditor` | `roles/bigquery.dataViewer` |
| `roles/dataform.editor` | `roles/dataform.viewer` ⚠️ |
| `roles/composer.admin` | `roles/composer.environmentAndStorageObjectViewer` |
| `roles/dataproc.worker` | `roles/dataproc.viewer` |
| `roles/storage.objectAdmin` | `roles/storage.objectViewer` |
| `roles/logging.viewer` | `roles/logging.viewer` |
| `roles/iam.mlEngineer` | *(removida — persona já inclui ações de criar/gerenciar modelo)* |
| `roles/notebooks.runner` | *(removida — executar notebook não é leitura)* |

⚠️ = nome que acredito existir pelo padrão de nomenclatura do Google, mas não confirmado via documentação — confira com `gcloud iam roles describe <role>` antes do primeiro `apply` em produção. Lista completa: `roles/dataplex.catalogEditor`, `roles/dataplex.catalogViewer`, `roles/notebooks.viewer`, `roles/dataform.viewer`.

## Próximos passos sugeridos (fora do escopo deste módulo)

- Confirmar os nomes de role sinalizados como não verificados (`roles/dataform.viewer`, `roles/dataplex.catalogViewer`, `roles/dataplex.catalogEditor`, `roles/notebooks.viewer`) via `gcloud iam roles describe` antes do primeiro `apply` em produção — ver seção `ml_ops_profiles` acima.
- Revisar com o time se o perfil Data Engineer realmente não precisa de nenhuma role adicional além das que já tinha (ver "Achado ao migrar" acima) — o bundle que ele recebia por engano (via cópia da custom role de ML Engineer) foi removido, não substituído por outra coisa.
- Revisar, com os donos de cada perfil, se as roles ainda amplas em nível de projeto (`bigquery.dataEditor`, `composer.admin`, `logging.admin`) podem ser reduzidas a escopos mais específicos (dataset/ambiente) em vez de projeto inteiro.
- Revisar se o grupo antes hardcoded no módulo `iam` (`G_GCP_RISCFAB_DTSC@corp.caixa.gov.br`, já removido de lá) ainda deve receber os acessos que tinha (`roles/aiplatform.admin`, `roles/iam.dataScientist`) e, se sim, declará-lo explicitamente em `iam_bindings` no `.tfvars`/`locals.tf` do stack, por ambiente.
