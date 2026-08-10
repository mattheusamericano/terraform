# iam

Módulo Terraform que centraliza a governança de **IAM de um projeto** (voltado a uma plataforma de dados/ML): cria Service Accounts internas, roles customizadas (custom roles) para perfis de dados/ML, e concede permissões tanto a essas Service Accounts quanto a grupos organizacionais (via `google_project_iam_member` e `google_project_iam_binding`). É um módulo grande, organizado em vários arquivos por responsabilidade — veja a seção "Organização dos arquivos" abaixo.

## Organização dos arquivos

- **`service_account.tf`** — cria as Service Accounts internas (`google_service_account.sa`), uma para cada entrada de `sa_settings`. As demais permissões do módulo são concedidas a essas SAs pela chave usada nesse mapa (ex.: `sa-comp`, `sa-global`, `sa-cr-acc`, `sa-lg-vw`, `sa-lg-wr`, `sa-lg-adm`).
- **`custom_roles.tf`** — define as roles customizadas de projeto (`google_project_iam_custom_role`) usadas pelos perfis de dados/ML: Dataform, ML Viewer, ML Engineer, Engenheiro de Dados e Cientista de Dados.
- **`roles.tf`** — concede, via `google_project_iam_member`, um grande conjunto de permissões pontuais (predefinidas e customizadas) tanto às Service Accounts criadas em `service_account.tf` quanto a grupos organizacionais (`ml_engineer_org_group`, `ml_data_scientist_org_group`, `data_engineer_org_group` e alguns grupos fixos do domínio RISCFAB).
- **`iam_binging.tf`** *(nome do arquivo contém esse typo no repositório)* — concede, via `google_project_iam_binding` (binding autoritativo, substitui a lista de membros da role), as roles customizadas de ML Engineer, Data Scientist e Engenheiro de Dados (definidas em `custom_roles.tf`) aos respectivos grupos organizacionais, além de `roles/notebooks.runner` para Data Scientist e Engenheiro de Dados.
- **`composer.tf`** — concede à Service Account `sa-comp` o conjunto de roles definido em `permissions_sa_composer` (pensado para a Service Account usada pelo Cloud Composer).
- **`globals.tf`** — concede à Service Account `sa-global` o conjunto de roles definido em `permissions_sa_global` (permissões "globais" comuns ao projeto).
- **`main.tf`** — atualmente não possui nenhum recurso ativo; contém apenas blocos comentados (concessão de `roles/storage.admin` a grupos RISCFAB) pendentes de decisão, conforme o próprio comentário no código (`CONSULTAR SE VAMOS DAR ESSE ACESSO`).
- **`variables.tf`** — declara todas as variáveis de entrada do módulo.
- **`output.tf`** — expõe os e-mails das Service Accounts criadas.

## Recursos criados

- `google_service_account.sa` *(service_account.tf)* — cria uma Service Account por entrada de `sa_settings`, com `account_id = "<chave>-<sigla>-<workspace>"`.
- `google_project_iam_custom_role.dataform_service_account_role` *(custom_roles.tf)* — role customizada `dataformServiceAccountBasicRole`, permissões básicas para a SA de usuário do Dataform.
- `google_project_iam_custom_role.machine_learning_viewer` *(custom_roles.tf)* — role customizada `ENG_VIEWER`, visualização de recursos de ML.
- `google_project_iam_custom_role.machine_learning_engineer` *(custom_roles.tf)* — role customizada `ENG_MLOPS`, permissões de MLOps.
- `google_project_iam_custom_role.data_engineer` *(custom_roles.tf)* — role customizada `ENG_DADOS`, permissões de engenharia de dados.
- `google_project_iam_custom_role.machine_learning_data_scientist` *(custom_roles.tf)* — role customizada `CIENTISTA_DADOS`, permissões de ciência de dados.
- `google_project_iam_binding.machine_learning_engineer_project_group_binding` *(iam_binging.tf)* — vincula a role customizada de ML Engineer ao grupo `ml_engineer_org_group`.
- `google_project_iam_binding.machine_learning_google_noteviwer` *(iam_binging.tf)* — vincula `roles/notebooks.runner` aos grupos de Data Scientist e Engenheiro de Dados.
- `google_project_iam_binding.ml_data_scientist_project_group_binding` *(iam_binging.tf)* — vincula a role customizada de Data Scientist ao grupo `ml_data_scientist_org_group`.
- `google_project_iam_binding.data_engineer_project_group_binding` *(iam_binging.tf)* — vincula a role customizada de Engenheiro de Dados ao grupo `data_engineer_org_group`.
- `google_project_iam_member.permissions_sa_composer` *(composer.tf)* — concede cada role de `permissions_sa_composer` à SA `sa-comp`.
- `google_project_iam_member.permissions_sa_global` *(globals.tf)* — concede cada role de `permissions_sa_global` à SA `sa-global`.
- `google_project_iam_member.*` *(roles.tf)* — cerca de 25 concessões pontuais de roles predefinidas e customizadas, entre elas:
  - `core_secret_accessor` (SA `sa-cr-acc` → `secretmanager.secretAccessor`), `log_viewer_accessor`/`log_writer_accessor`/`log_admin_accessor` (SAs `sa-lg-vw`/`sa-lg-wr`/`sa-lg-adm` → `logging.viewer`/`logging.logWriter`/`logging.admin`), `log_writer_bq_editor_member` (SA `sa-lg-wr` → `bigquery.dataEditor`);
  - permissões para `ml_engineer_org_group` (IAP, Cloud Run developer, AI Platform viewer, IAM role viewer, Cloud Build connection admin, Storage admin via grupo RISCFAB fixo `G_GCP_RISCFAB_DTSC`, AI Platform admin);
  - permissões para `ml_data_scientist_org_group` (AI Platform user, IAM role viewer, Dataform editor, Storage admin, IAM Data Scientist);
  - permissões para `data_engineer_org_group` (AI Platform viewer, IAM role viewer, BigQuery data editor, Dataform editor, Composer admin, Dataproc worker, Storage admin, Notebooks runner, Logging viewer, IAM ML Engineer).

### Data sources

Nenhum data source é utilizado neste módulo.

## Como usar

```hcl
module "iam" {
  source = "./gcp/iam"

  iam_settings = {
    iam = {
      project_id = "meu-projeto-gcp"
    }
  }

  sa_settings = {
    sa-comp   = { project_id = "meu-projeto-gcp", sigla = "plat", display_name = "SA Cloud Composer" }
    sa-global = { project_id = "meu-projeto-gcp", sigla = "plat", display_name = "SA Global do Projeto" }
    sa-cr-acc = { project_id = "meu-projeto-gcp", sigla = "plat", display_name = "SA Core - Secret Accessor" }
    sa-lg-vw  = { project_id = "meu-projeto-gcp", sigla = "plat", display_name = "SA Log Viewer" }
    sa-lg-wr  = { project_id = "meu-projeto-gcp", sigla = "plat", display_name = "SA Log Writer" }
    sa-lg-adm = { project_id = "meu-projeto-gcp", sigla = "plat", display_name = "SA Log Admin" }
  }

  permissions_sa_composer = {
    composer_worker    = "roles/composer.worker"
    composer_serviceAgent = "roles/composer.ServiceAgentV2Ext"
  }

  permissions_sa_global = {
    log_writer = "roles/logging.logWriter"
  }

  permissions_bigquery_dataform = ["roles/bigquery.dataEditor", "roles/bigquery.jobUser"]
  permissions_ml_viewer          = ["roles/aiplatform.viewer"]
  permissions_ml_engineer        = ["roles/aiplatform.user", "roles/storage.objectAdmin"]
  permissions_data_engineer      = ["roles/bigquery.dataEditor", "roles/dataproc.worker"]
  permissions_ml_data_scientis   = ["roles/aiplatform.user", "roles/notebooks.runner"]

  ml_engineer_org_group       = "g-ml-engineers@empresa.com"
  ml_data_scientist_org_group = "g-data-scientists@empresa.com"
  data_engineer_org_group     = "g-data-engineers@empresa.com"
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `sa_settings` | Mapa de Service Accounts a serem criadas. A chave é usada como referência (`sa["<chave>"]`) em todos os outros arquivos do módulo para conceder permissões. | `map(object({ project_id=string, display_name=string, sigla=string }))` | — | sim |
| `iam_settings` | Mapa contendo os dados do projeto onde as permissões serão aplicadas. **Sempre acessado com a chave fixa `"iam"`** (`var.iam_settings["iam"].project_id`) em todos os recursos do módulo. | `map(object({ project_id=string }))` | — | sim |
| `permissions_sa_global` | Mapa de roles (chave arbitrária → role) concedidas à Service Account `sa-global`. | `map(string)` | — | sim |
| `permissions_sa_composer` | Mapa de roles (chave arbitrária → role) concedidas à Service Account `sa-comp`. | `map(string)` | — | sim |
| `permissions_bigquery_dataform` | Lista de permissões (IAM permissions, não roles) da role customizada `dataformServiceAccountBasicRole`. | `list(string)` | — | sim |
| `permissions_ml_viewer` | Lista de permissões da role customizada `ENG_VIEWER`. | `list(string)` | — | sim |
| `permissions_ml_engineer` | Lista de permissões da role customizada `ENG_MLOPS`. | `list(string)` | — | sim |
| `permissions_data_engineer` | Lista de permissões da role customizada `ENG_DADOS`. | `list(string)` | — | sim |
| `permissions_ml_data_scientis` | Lista de permissões da role customizada `CIENTISTA_DADOS`. | `list(string)` | — | sim |
| `ml_engineer_org_group` | Grupo organizacional de Machine Learning Engineers, usado nos bindings/roles de `iam_binging.tf` e `roles.tf`. | `string` | `null` | não |
| `ml_data_scientist_org_group` | Grupo organizacional de Cientistas de Dados. | `string` | `null` | não |
| `data_engineer_org_group` | Grupo organizacional de Engenheiros de Dados. | `string` | `null` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `service_account_emails` | Mapa com os e-mails de todas as Service Accounts criadas, indexado pela chave usada em `sa_settings`. |

## Observações

- `var.iam_settings` é um mapa, mas todo o módulo acessa apenas a chave literal `"iam"` (`var.iam_settings["iam"].project_id`) — a variável deve obrigatoriamente conter essa chave, o projeto de todos os recursos do módulo é sempre esse único projeto.
- Os arquivos `roles.tf`, `composer.tf` e `globals.tf` referenciam Service Accounts por chave fixa (`sa["sa-comp"]`, `sa["sa-global"]`, `sa["sa-cr-acc"]`, `sa["sa-lg-vw"]`, `sa["sa-lg-wr"]`, `sa["sa-lg-adm"]`) — essas chaves **precisam existir** em `sa_settings`, caso contrário o `terraform plan/apply` falha com erro de índice inválido no mapa.
- `main.tf` não cria nenhum recurso ativo hoje — contém apenas trechos comentados aguardando decisão sobre conceder `roles/storage.admin` a grupos RISCFAB.
- Há um grupo do Google **hardcoded** no código (`G_GCP_RISCFAB_DTSC@corp.caixa.gov.br`) em dois recursos de `roles.tf` (`riscfab_datascientist` e `ml_platform_user_riscfab`) — não é parametrizado por variável, portanto é fixo para qualquer instância do módulo.
- `google_project_iam_binding` (usado em `iam_binging.tf`) é **autoritativo**: substitui integralmente a lista de membros da role a cada apply. Diferente de `google_project_iam_member` (usado nos demais arquivos), que apenas adiciona um membro sem remover outros já existentes na role. Misturar os dois tipos de recurso na mesma role pode gerar conflitos de estado — atualmente o módulo usa `iam_binding` apenas para as roles customizadas e `notebooks.runner`, e `iam_member` para todo o restante.
- As roles customizadas definidas em `custom_roles.tf` recebem suas permissões inteiramente das listas passadas em `permissions_bigquery_dataform`, `permissions_ml_viewer`, `permissions_ml_engineer`, `permissions_data_engineer` e `permissions_ml_data_scientis` — qualquer alteração de escopo de acesso desses perfis deve ser feita ajustando essas listas, não o `.tf`.
