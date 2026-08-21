# 🧠 gcp-coffer-credpj-model (MLOps & Model Lifecycle)

[![Platform: Google Cloud](https://img.shields.io/badge/GCP-Google%20Cloud-4285F4?logo=google-cloud&logoColor=white)](#)
[![CD: GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](#)
[![CD: Cloud Build](https://img.shields.io/badge/CI%2FCD-Cloud%20Build-4285F4?logo=google-cloud&logoColor=white)](#)
[![Orchestration: Kubeflow](https://img.shields.io/badge/Orchestration-Kubeflow%20Pipelines%20(KFP)-00C7B7)](#)

> [!NOTE]
> Repositório de **Modelagem Estatística e MLOps** do produto **`credpj`** integrado ao ecossistema Coffer.

Este repositório armazena os códigos de treinamento, validação e pipelines do Vertex AI Pipelines (Kubeflow) para predição e análise de modelos de risco de cr édito PJ, incluindo as configurações declarativas do ciclo de vida em `model-config.yaml`.

---

## 📂 Estrutura do Repositório

```text
gcp-coffer-credpj-model/
├── README.md                # Este manual de referência
├── requirements.txt        # Dependências Python (Vertex AI SDK, KFP, etc.)
├── model-config.yaml       # Configuração declarativa do ciclo de vida e Serving do modelo
│
├── .github/workflows/      # ⚙️ CI/CD: Workflow de acionamento via GitHub Actions
│   └── deploy.yml          # Integração e deploy MDL (main) e INF (tags v*)
│
├── .cloudbuild/            # 🛠️ PLATAFORMA: Configurações de compilação e disparo do GCP
│   ├── dev.yaml            # Pipeline do Cloud Build para Desenvolvimento / Modelagem (MDL)
│   └── prod.yaml           # Pipeline do Cloud Build para Produção / Inferência (INF)
│
├── notebooks/              # 📓 Pesquisa: Notebooks Jupyter de experimentação local
│   └── .gitkeep
│
├── pipelines/              # 🏗️ Orquestração: DAGs e componentes de Machine Learning
│   └── pipeline.py         # Pipeline Kubeflow definindo o fluxo de treino e deploy
│
└── src/                    # 🐍 Computação: Lógica e scripts adicionais (SQL BQML, etc.)
    ├── train_model.sql     # Query de treinamento BigQuery ML (BQML)
    └── evaluate_model.sql  # Query de avaliação de performance estatística
```

---

## 🏗️ Ciclo de Vida do Modelo (`model-config.yaml`)

O arquivo [model-config.yaml](model-config.yaml) orienta o deploy automatizado (GitOps) e o roteamento de tráfego do modelo no ambiente de produção:
* **Canary Deployment**: Especificação automatizada para divisão estatística de tráfego (ex: 90% para o endpoint estável, 10% para o novo candidato).
* **Grounding e Grounding Context**: Definições de contexto e grounding analítico para as rotinas de inteligência artificial de apoio à decisão de crédito.
* **Segurança e Isolamento**: Todas as execuções de treinamento utilizam o service account dedicado `sa-iac-rsk-credpj-mdl-prd@` isolado em sua respectiva VPC de modelagem.

---

## 🚀 Integração e Entrega Contínua (CI/CD & GitOps)

O ciclo de entrega e treinamento do modelo de crédito PJ é totalmente automatizado via GitHub Actions e integrado ao GCP por meio de **Workload Identity Federation (WIF)**:

### 1. Desenvolvimento e Homologação (Branch `main`)
* **Gatilho**: Push na branch `main`.
* **Ação**: Executa o job de treino e validação no ambiente de modelagem (`prj-rsk-credpj-mdl-prd`).
* **Autenticação**: Service Account de modelagem (`sa-iac-rsk-credpj-mdl-prd@prj-rsk-credpj-mdl-prd.iam.gserviceaccount.com`).
* **Processo**: Submete a compilação do pipeline usando a configuração `.cloudbuild/dev.yaml` executando em Worker Pool Privado.

### 2. Produção e Promoção de Modelos (Tags `v*`)
* **Gatilho**: Publicação de tags seguindo o padrão semântico `v*` (ex: `v1.0.34`).
* **Ação**: Dispara o pipeline de orquestração produtiva diretamente no projeto de inferência (`prj-rsk-credpj-inf-prd`).
* **Autenticação**: Service Account de inferência (`sa-iac-rsk-credpj-inf-prd@prj-rsk-credpj-inf-prd.iam.gserviceaccount.com`).
* **Processo**:
  1. Submete a execução do build usando a configuração `.cloudbuild/prod.yaml` executando em Worker Pool Privado no spoke de inferência.
  2. Compila e faz upload do template do pipeline da Vertex AI para o GCS.
  3. Atualiza e aciona o Cloud Workflow (`credpj-model-promotion-workflow`) de forma assíncrona.
  4. O workflow executa as validações analíticas de Dataform, inicia o treinamento produtivo e aplica o Canary Deployment de forma totalmente automatizada.

### 3. Variáveis do Cloud Build (`.cloudbuild/dev.yaml` e `.cloudbuild/prod.yaml`)

Nenhum dos dois arquivos tem projeto, região, nome de dataset, nome do Workflow etc. mais hardcoded direto no meio do script — tudo isso agora é declarado no bloco `substitutions:` no topo de cada arquivo, com o mesmo valor que já estava em uso hoje como default (ou seja, rodar sem passar nada continua se comportando exatamente como antes).

**Projeto:** não é uma substitution — vem de `$PROJECT_ID`, variável nativa do Cloud Build, que é sempre igual ao valor passado em `--project` no `gcloud builds submit` (é isso que já faz `dev.yaml` rodar no projeto de modelagem e `prod.yaml` no de inferência, conforme `.github/workflows/deploy.yml`).

**`.cloudbuild/dev.yaml`**

| Variável | Default | Para que serve |
|---|---|---|
| `_REGION` | `southamerica-east1` | Região usada na criação do dataset e (implicitamente) no pipeline |
| `_MODELS_DATASET` | `models` | Nome do dataset BigQuery de modelos, criado se não existir |
| `_ARTIFACT_REGISTRY_INDEX_URL` | URL do índice PyPI privado (Artifact Registry) | Repositório de onde `pip install` baixa `kfp`, `google-cloud-pipeline-components`, etc. |

**`.cloudbuild/prod.yaml`**

| Variável | Default | Para que serve |
|---|---|---|
| `_TAG_NAME` | `v1.0.0` | Tag da release sendo promovida (já existia; `deploy.yml` sempre repassa a tag real via `--substitutions`) |
| `_REGION` | `southamerica-east1` | Região do Workflow e dos parâmetros repassados a ele |
| `_WORKFLOW_NAME` | `credpj-model-promotion-workflow` | Nome do Cloud Workflow implantado e executado |
| `_WORKFLOW_SOURCE_FILE` | `pipelines/model_promotion_workflow.yaml` | Arquivo-fonte do Workflow que é implantado |
| `_DATAFORM_REPOSITORY_ID` | `df-repo-pub-des` | Repositório Dataform que o Workflow compila/executa |
| `_DATAFORM_GIT_COMMITISH` | `dataform-risco-pub` | Branch/commit do Dataform usado na compilação |
| `_DATAFORM_SA_PREFIX` | `sa-df-pub-des` | Prefixo da Service Account do Dataform (o e-mail final é `<prefixo>@<project_id>.iam.gserviceaccount.com`) |
| `_ARTIFACT_REGISTRY_INDEX_URL` | URL do índice PyPI privado (Artifact Registry) | Mesmo repositório usado em `dev.yaml`, para instalar `pyyaml` |

`project_id`, `dataset_id`, `pipeline_root` e `service_account` do ambiente de produção **não** viraram substitution — continuam vindo de `model-config.yaml` (`model_training.environments.production`), que já era a fonte única de verdade para esses dados antes desta mudança. A regra de bolso: se o valor descreve *onde/como o modelo roda* (projeto, dataset, bucket, SA de execução), ele vive em `model-config.yaml`; se descreve *como o build/CI está configurado* (região do build, nome do Workflow, repositório/branch do Dataform, índice do PyPI), ele vive em `substitutions:`.

**Como sobrescrever uma variável** sem editar o arquivo, tanto rodando manualmente quanto num Trigger do Cloud Build:

```bash
gcloud builds submit --config=.cloudbuild/prod.yaml \
  --project=prj-rsk-credpj-inf-prd \
  --substitutions=_TAG_NAME=v2.1.0,_DATAFORM_GIT_COMMITISH=outra-branch \
  .
```

Hoje quem dispara os dois builds é o próprio `.github/workflows/deploy.yml`, via `gcloud builds submit` (não um Cloud Build Trigger nativo) — ele já repassa `_TAG_NAME` dessa forma para `prod.yaml` (`--substitutions="_TAG_NAME=${{ github.ref_name }}"`). Se algum dia isso migrar para um Cloud Build Trigger nativo, os mesmos nomes de variável podem ser definidos na seção "Variáveis de substituição" da configuração do trigger — o valor passado ali (ou via `--substitutions`) sempre tem prioridade sobre o default declarado no YAML.
