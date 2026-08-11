# terraform

Repositório de Infraestrutura como Código (IaC) multi-cloud, com foco em GCP (principal) e IBM Cloud. O repositório é organizado em quatro pastas núcleo que formam o fluxo padrão de provisionamento, do módulo reutilizável até a pipeline que aplica em produção.

## Fluxo núcleo

O provisionamento segue sempre a mesma cadeia, nesta ordem:

```
terraform-code  →  terraform-template-arch  →  terraform-template-variables  →  terraform-workflow
  (módulos)          (orquestração/stack)         (valores por ambiente)          (pipelines CI/CD)
```

### 1. `terraform-code/`

Onde vivem os **módulos Terraform reutilizáveis**, um por recurso de cloud, organizados por provider (`gcp/`, `ibm/`). Cada módulo é autocontido e nunca é aplicado diretamente — ele é sempre consumido por uma stack em `terraform-template-arch/`.

Convenções seguidas pelos módulos existentes:

- **Um recurso (ou conjunto coeso) por módulo**, nomeado com o nome do recurso (`bucket`, `gke`, `cloud_sql`, `iam`, `pubsub`, etc.).
- **`for_each` sobre `map(object({...}))`** — todo módulo recebe uma variável `<recurso>_settings` do tipo `map(object({...}))` e nunca cria um recurso único direto; isso permite criar zero, um ou vários recursos do mesmo tipo com a mesma chamada de módulo.
- **Nomenclatura de recursos**: `"${each.key}-${each.value.sigla}-${terraform.workspace}"` — chave do mapa + sigla do time/solução + workspace (ambiente).
- **Arquivos separados por responsabilidade**: `main.tf` (recurso principal), `variables.tf`, `outputs.tf`, `iam.tf` (bindings de IAM), `data.tf` (data sources), `locals.tf` e `sa.tf` (service account) quando necessário.
- **`optional()` com defaults** nos campos não críticos da variável; campos como `project_id`, `sigla` e `region` são sempre obrigatórios.
- **Criptografia via Cloud KMS (CMEK)** é o padrão em módulos que armazenam dados (bucket, BigQuery, Firestore, Cloud SQL) — normalmente via `kms_project_id`, `key_ring`/`kms_key_name`, `key_crypto`.
- **README.md por módulo**, com as seções: descrição, recursos criados, exemplo de uso (`module "..." { ... }`), tabela de inputs, tabela de outputs e observações relevantes (comportamento não óbvio, trade-offs de segurança, etc.).
- **`labels`/tags não são hardcoded no módulo** — elas chegam prontas via variável, pois são injetadas pela stack (ver item 2).

### 2. `terraform-template-arch/`

A camada de **orquestração** (stack/root module). Aqui os módulos de `terraform-code/` são instanciados e conectados entre si — é o "montar o quebra-cabeça". Cada arquitetura (ex.: `arch-padrao`, `arch-iam`) tem sua própria pasta `stacks/` com:

- `backend.tf` — backend remoto de state (GCS), com bucket parametrizado.
- `providers.tf` — versões fixadas dos providers (`~> X.Y.Z`) e configuração básica de projeto/região.
- `locals.tf` — `common_labels` (labels padrão mescladas em todo recurso) e `apis_list` (APIs do GCP a habilitar via módulo `project_service`).
- `variables.tf` — uma flag booleana `enabled_<módulo>` por módulo consumido (default `false`) mais o `<recurso>_settings` map(object) correspondente.
- `main.tf` — uma chamada `module "..." { source = "../../terraform-code/gcp/<módulo>" ... }` por módulo, com o mapa de settings condicionado pela flag (`var.enabled_x ? {...} : {}`) e `depends_on` explícito onde há dependência real (ex.: `gke_nodepool` depende de `gke`; `cloud_sql_database` depende de `cloud_sql`).
- `tfvars/` — arquivo de exemplo com placeholders (`__project_id__`, `__region__`, etc.) a substituir por ambiente.

O padrão de "reaproveitar entre projetos" vem daqui: como cada módulo só é chamado uma vez por arquitetura e as flags controlam o que é criado, a mesma stack serve de base para múltiplos projetos — muda-se apenas o `.tfvars`.

### 3. `terraform-template-variables/`

Onde ficam os **valores reais de cada variável** referenciada em `terraform-template-arch/`, um arquivo YAML por arquitetura e ambiente (ex.: `variables-iac-padrao-des.yaml` para o ambiente `des` da `arch-padrao`). É o que substitui os placeholders `__algo__` antes do `terraform plan`/`apply` — normalmente processado pela própria pipeline.

### 4. `terraform-workflow/`

As **pipelines do Azure DevOps** que executam o fluxo acima:

- `terraform/` — templates reutilizáveis de plan, apply, destroy, publicação/extração de artifacts, versão do Terraform e custo (`terraform-gcp-cost.yaml`).
- `codescan/checkov-terraform-scan.yaml` — scan de segurança com Checkov (soft-fail, saída JUnit publicada nos resultados de teste).
- `scripts/bucket-tfstate-gcp.yaml` — criação do bucket de state.
- `ado-pipeline-extends.yaml` — pipeline principal que estende os templates acima.

## Outras pastas do repositório

Pastas fora do núcleo, com propósitos específicos: `asset-inventory/` (scripts de inventário de assets GCP via BigQuery), `runner-git-gcp/` (runners self-hosted do Azure Pipelines no GCP), `yaml/` (pipelines avulsas de criação de projeto/bucket de state), `test-cloudbuild-with-github/` (POC de Cloud Build + GitHub).

## Próximos passos

Este README documenta o padrão atual identificado nos módulos e stacks existentes. A ideia é evoluir esse padrão para um skill do Claude, de forma que novos módulos (de qualquer cloud) sejam gerados automaticamente seguindo essas convenções.
