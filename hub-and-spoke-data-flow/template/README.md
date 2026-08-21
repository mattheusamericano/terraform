# Template — Fluxo de CI/CD MLOps (Hub-and-Spoke)

Template genérico de um fluxo de CI/CD MLOps hub-and-spoke: GitHub Actions dispara Cloud Build (`dev.yaml` para modelagem, `prod.yaml` para inferência), que treina/submete um pipeline Vertex AI e, em produção, implanta e executa um Cloud Workflow que roda Dataform e publica um listing no Analytics Hub. Use este template para replicar exatamente esse cenário em outro produto/modelo, sem copiar e adaptar manualmente os hardcodes de cada arquivo.

> Este conteúdo é para viver na **raiz de um repositório próprio** (sem nenhuma pasta por cima) — todos os caminhos abaixo já são relativos à raiz do repositório.

## O que este template cobre

Cobre a **esteira de CI/CD completa** (gatilho do GitHub Actions, os dois arquivos do Cloud Build, o `model-config.yaml` que os alimenta e o Cloud Workflow de promoção para produção) **e** um pipeline de ML funcional de ponta a ponta como referência:
- `pipelines/pipeline.py` — pipeline Kubeflow/Vertex AI já pronto (treino BQML XGBoost + avaliação + exportação + deploy com Canary Split num Endpoint privado). Já lê `model-config.yaml` para projeto/dataset/bucket/service account — normalmente você só mexe nisso se mudar a orquestração em si.
- `src/train_model.sql`, `src/evaluate_model.sql`, `src/export_model.sql` — exemplo de treino BQML (classificador de risco de crédito). É o pedaço mais específico do negócio: troque a tabela de origem e as colunas de features/label pelo seu conjunto de dados real quando for além do pontapé inicial.

Isso permite gerar o template e já rodar o fluxo de ponta a ponta contra um projeto de teste antes de trocar qualquer lógica de modelo.

## O que este template NÃO conecta ainda

O Cloud Workflow (`pipelines/model_promotion_workflow.yaml`) hoje só orquestra **Dataform + publicação do listing no Analytics Hub** — os steps do workflow chamam a API do Dataform e a do Analytics Hub diretamente, sem envolver `pipelines/pipeline.py` nem Vertex AI Pipelines em nenhum momento.

As variáveis `pipeline_root`, `template_uri` e `service_account`, declaradas em `init_variables` do workflow (recebidas do `.cloudbuild/prod.yaml`, que já as monta a partir de `model-config.yaml`), **não são usadas em nenhum step** — ficam ali como exemplo/reserva para o dia em que este mesmo workflow também disparar o pipeline de treino/deploy do Vertex AI (usando o `pipeline.json` gerado por `pipelines/pipeline.py`). Não é bug nem esquecimento: é intencional, só não está em uso agora.

Ou seja, no fluxo atual, treino via Vertex AI só acontece pelo `dev.yaml` (`pipelines/pipeline.py --environment=development --submit`). Não existe hoje, nem em `prod.yaml` nem no workflow, um step que rode o pipeline de treino/inferência em produção — só a parte de dados (Dataform → Analytics Hub) é automatizada em produção por enquanto.

## Estrutura

```text
<raiz do repositório>/
├── README.md                              # este arquivo
├── vars.example.env                       # exemplo de variáveis a preencher
├── generate.sh                            # copia + preenche o template automaticamente
├── requirements.txt                       # dependências Python (genérico)
├── .gcloudignore                          # genérico, não precisa editar
├── model-config.yaml                      # config declarativa do ciclo de vida do modelo
├── .github/workflows/deploy.yml           # gatilho de CI/CD
├── .cloudbuild/
│   ├── dev.yaml                           # build de modelagem (branch)
│   └── prod.yaml                          # build de inferência (tags v*)
├── pipelines/
│   ├── pipeline.py                        # pipeline Vertex AI (treino + deploy) — referência funcional
│   └── model_promotion_workflow.yaml      # Cloud Workflow de promoção
└── src/
    ├── train_model.sql                    # exemplo de treino BQML — trocar pelo seu feature set
    ├── evaluate_model.sql                 # exemplo de avaliação BQML
    └── export_model.sql                   # exportação do modelo para o GCS
```

## Como usar

### Opção 1 — automática (`generate.sh`)

A partir da raiz deste repositório:

```bash
cp vars.example.env vars.env      # edite vars.env com os dados reais do novo produto
./generate.sh vars.env ../repositorio-do-novo-produto
```

O script copia todos os arquivos deste repositório para `../repositorio-do-novo-produto`, substitui cada `__chave__` pelo valor definido em `vars.env` e avisa se sobrou algum placeholder sem preencher (comparado por nome — se você usar uma chave que não existe em nenhum arquivo do template, ou esquecer uma que existe, o aviso aparece). `vars.env` não é versionado por padrão (adicione ao `.gitignore` se ele guardar algo sensível) — o `vars.example.env` é só o modelo.

### Opção 2 — manual

Sem usar o script: substitua manualmente, direto neste repositório, cada `__chave__` (em minúsculo, ex.: `__region__`) pelo valor correspondente. A tabela abaixo lista todos os placeholders usados.

## Variáveis do template

| Placeholder | Chave em `vars.env` | Onde aparece | Exemplo |
|---|---|---|---|
| `__product__` | `PRODUCT` | `model-config.yaml` | `credpj` |
| `__domain__` | `DOMAIN` | `model-config.yaml` | `rsk` |
| `__endpoint_name__` | `ENDPOINT_NAME` | `model-config.yaml`, `pipeline.py` (fallback) | `endpoint-credpj-risk` |
| `__model_id__` | `MODEL_ID` | `model-config.yaml`, `src/*.sql` | `credpj_risk_xgb_v1` |
| `__pipeline_name__` | `PIPELINE_NAME` | `model-config.yaml`, `pipeline.py` (fallback) | `credpj-risk-xgb-pipeline` |
| `__dataset_id__` | `DATASET_ID` | `model-config.yaml`, `model_promotion_workflow.yaml`, `pipeline.py` (fallback) | `served` |
| `__models_dataset__` | `MODELS_DATASET` | `.cloudbuild/dev.yaml`, `src/*.sql` | `models` |
| `__region__` | `REGION` | todos, inclusive `pipeline.py` | `southamerica-east1` |
| `__train_project_id__` | `TRAIN_PROJECT_ID` | `model-config.yaml`, `deploy.yml`, `pipeline.py` (fallback) | `prj-meuproduto-mdl-prd` |
| `__serving_project_id__` | `SERVING_PROJECT_ID` | `model-config.yaml`, `deploy.yml`, `model_promotion_workflow.yaml` | `prj-meuproduto-inf-prd` |
| `__hub_project_id__` | `HUB_PROJECT_ID` | `model_promotion_workflow.yaml` | `prj-hub-poc` |
| `__train_pipeline_root__` | `TRAIN_PIPELINE_ROOT` | `model-config.yaml`, `pipeline.py` | `gs://bucket-.../pipeline_root` |
| `__train_models_export_uri__` | `TRAIN_MODELS_EXPORT_URI` | `src/export_model.sql` | `gs://bucket-.../models/meuproduto_risk_xgb_v1` |
| `__serving_pipeline_root__` | `SERVING_PIPELINE_ROOT` | `model-config.yaml` (exigido pelo schema), `model_promotion_workflow.yaml` (não usado) | `gs://bucket-.../pipeline_root` |
| `__serving_template_uri__` | `SERVING_TEMPLATE_URI` | `model_promotion_workflow.yaml` (não usado) | `gs://bucket-.../pipeline_root/pipeline.json` |
| `__serving_bucket_name__` | `SERVING_BUCKET_NAME` | `model_promotion_workflow.yaml` (não usado) | `bucket-data-meuproduto-inf` |
| `__train_service_account__` | `TRAIN_SERVICE_ACCOUNT` | `model-config.yaml`, `pipeline.py` (fallback) | `sa-vertex-ai-pipeline@...` |
| `__serving_service_account__` | `SERVING_SERVICE_ACCOUNT` | `model-config.yaml`, `model_promotion_workflow.yaml` | `sa-vertex-ai-pipeline@...` |
| `__artifact_registry_index_url__` | `ARTIFACT_REGISTRY_INDEX_URL` | `.cloudbuild/dev.yaml`, `.cloudbuild/prod.yaml` | URL do índice PyPI privado |
| `__workflow_name__` | `WORKFLOW_NAME` | `.cloudbuild/prod.yaml` | `meuproduto-model-promotion-workflow` |
| `__dataform_repository_id__` | `DATAFORM_REPOSITORY_ID` | `.cloudbuild/prod.yaml`, `model_promotion_workflow.yaml` | `df-repo-meuproduto` |
| `__dataform_git_commitish__` | `DATAFORM_GIT_COMMITISH` | `.cloudbuild/prod.yaml`, `model_promotion_workflow.yaml` | `main` |
| `__dataform_sa_prefix__` | `DATAFORM_SA_PREFIX` | `.cloudbuild/prod.yaml`, `model_promotion_workflow.yaml` | `sa-df-meuproduto` |
| `__data_exchange_id__` | `DATA_EXCHANGE_ID` | `model_promotion_workflow.yaml` | `exchange_meuproduto` |
| `__listing_id__` | `LISTING_ID` | `model_promotion_workflow.yaml` | `listing_meuproduto` |
| `__branch_name__` | `BRANCH_NAME` | `deploy.yml` | `meuproduto-model` |
| `__workerpool_dev__` | `WORKERPOOL_DEV` | `deploy.yml` | `workerpool-meuproduto-mdl` |
| `__workerpool_prod__` | `WORKERPOOL_PROD` | `deploy.yml` | `workerpool-meuproduto-inf` |

## Dois mecanismos de variável — não confunda os dois

1. **Placeholders `__chave__`** (este README, `vars.env`, `generate.sh`): preenchidos **uma vez**, quando o template é instanciado para um novo produto. Depois de gerado, eles não existem mais nos arquivos — viraram texto fixo.
2. **`substitutions:` do Cloud Build** (dentro de `.cloudbuild/dev.yaml`/`prod.yaml`, ex.: `_REGION`, `_TAG_NAME`): continuam existindo no arquivo gerado, com o valor do placeholder como *default*. Servem para variar algo **por execução de build**, sem editar o arquivo, via `gcloud builds submit --substitutions=_VAR=valor` — é assim que `deploy.yml` já repassa a tag de release (`_TAG_NAME`) hoje.

Ou seja: `__workflow_name__` você preenche uma vez ao adotar o template (via `generate.sh`); `_TAG_NAME` você pode variar a cada build sem tocar em nada.

## Checklist depois de gerar

1. Confira `model-config.yaml` gerado — principalmente os buckets e service accounts, que costumam ter nomes com pequenas variações reais do que está no exemplo.
2. Rode o fluxo de ponta a ponta como veio (sem trocar nada em `pipelines/pipeline.py`/`src/*.sql`) contra um projeto de teste — é um pipeline funcional de treino BQML + deploy, serve pra validar que a esteira de CI/CD toda está correta antes de mexer em lógica de modelo.
3. Quando for além do pontapé inicial: troque `src/train_model.sql` (e `evaluate_model.sql`) pela tabela e pelas colunas de features/label do seu modelo real. `pipelines/pipeline.py` (orquestração, deploy, Canary Split) normalmente não precisa mudar.
4. Configure os secrets do repositório novo: `workload_identity_provider_gcp` e `service_account_gcp` (usados por `deploy.yml` para autenticar via Workload Identity Federation).
5. Confirme que os Worker Pools privados (`WORKERPOOL_DEV`/`WORKERPOOL_PROD`) e o Cloud Workflow (`WORKFLOW_NAME`) já existem nos projetos de destino, ou provisione-os antes do primeiro push/tag — este template não os cria, só os referencia.
6. `git push` na branch configurada em `BRANCH_NAME` dispara o job de modelagem; uma tag `v*` dispara o job de inferência/promoção.
