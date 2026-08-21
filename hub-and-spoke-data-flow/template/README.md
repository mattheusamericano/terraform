# Template — Fluxo de CI/CD MLOps (Hub-and-Spoke)

Versão genérica do fluxo de CI/CD usado em `hub-and-spoke-data-flow`: GitHub Actions dispara Cloud Build (`dev.yaml` para modelagem, `prod.yaml` para inferência), que treina/submete um pipeline Vertex AI e, em produção, implanta e executa um Cloud Workflow que roda Dataform e publica um listing no Analytics Hub. Use este template para replicar exatamente esse cenário em outro produto/modelo, sem copiar e adaptar manualmente os hardcodes de cada arquivo.

## O que este template cobre (e o que não cobre)

Cobre toda a **esteira de CI/CD**: gatilho do GitHub Actions, os dois arquivos do Cloud Build, o `model-config.yaml` que os alimenta e o Cloud Workflow de promoção para produção.

**Não** inclui a lógica do modelo em si — `pipelines/pipeline.py` (compilação do pipeline Kubeflow/Vertex) e `src/*.sql` (queries de treino/avaliação/exportação BQML). Esses arquivos são específicos de cada modelo e você precisa escrevê-los seguindo o contrato que a esteira espera:
- `pipelines/pipeline.py` deve aceitar `--submit` (chamado em `dev.yaml`) e ler `model-config.yaml` para saber projeto/dataset/bucket/service account do ambiente.
- O pipeline compilado deve gerar `pipeline.json` na raiz de `pipeline_root` (é isso que `template_uri` em `model_promotion_workflow.yaml` espera encontrar).

## Estrutura

```text
template/
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
└── pipelines/
    └── model_promotion_workflow.yaml      # Cloud Workflow de promoção
```

## Como usar

### Opção 1 — automática (`generate.sh`)

```bash
cd hub-and-spoke-data-flow/template
cp vars.example.env vars.env      # edite vars.env com os dados reais do seu produto
./generate.sh vars.env ../../meu-novo-produto
```

O script copia todos os arquivos do template para `../../meu-novo-produto`, substitui cada `__chave__` pelo valor definido em `vars.env` e avisa se sobrou algum placeholder sem preencher (comparado por nome — se você usar uma chave que não existe em nenhum arquivo do template, ou esquecer uma que existe, o aviso aparece). `vars.env` não é versionado por padrão nesta pasta (adicione ao `.gitignore` do repositório novo se ele guardar algo sensível) — o `vars.example.env` aqui é só o modelo.

### Opção 2 — manual

Copie a pasta inteira para a raiz do novo repositório e substitua manualmente cada `__chave__` (em minúsculo, ex.: `__region__`) pelo valor correspondente. A tabela abaixo lista todos os placeholders usados.

## Variáveis do template

| Placeholder | Chave em `vars.env` | Onde aparece | Exemplo |
|---|---|---|---|
| `__product__` | `PRODUCT` | `model-config.yaml` | `credpj` |
| `__domain__` | `DOMAIN` | `model-config.yaml` | `rsk` |
| `__endpoint_name__` | `ENDPOINT_NAME` | `model-config.yaml` | `endpoint-credpj-risk` |
| `__model_id__` | `MODEL_ID` | `model-config.yaml` | `credpj_risk_xgb_v1` |
| `__pipeline_name__` | `PIPELINE_NAME` | `model-config.yaml` | `credpj-risk-xgb-pipeline` |
| `__dataset_id__` | `DATASET_ID` | `model-config.yaml`, `model_promotion_workflow.yaml` | `served` |
| `__models_dataset__` | `MODELS_DATASET` | `.cloudbuild/dev.yaml` | `models` |
| `__region__` | `REGION` | todos | `southamerica-east1` |
| `__train_project_id__` | `TRAIN_PROJECT_ID` | `model-config.yaml`, `deploy.yml` | `prj-meuproduto-mdl-prd` |
| `__serving_project_id__` | `SERVING_PROJECT_ID` | `model-config.yaml`, `deploy.yml`, `model_promotion_workflow.yaml` | `prj-meuproduto-inf-prd` |
| `__hub_project_id__` | `HUB_PROJECT_ID` | `model_promotion_workflow.yaml` | `prj-hub-poc` |
| `__train_pipeline_root__` | `TRAIN_PIPELINE_ROOT` | `model-config.yaml` | `gs://bucket-.../pipeline_root` |
| `__serving_pipeline_root__` | `SERVING_PIPELINE_ROOT` | `model-config.yaml`, `model_promotion_workflow.yaml` | `gs://bucket-.../pipeline_root` |
| `__serving_template_uri__` | `SERVING_TEMPLATE_URI` | `model_promotion_workflow.yaml` | `gs://bucket-.../pipeline_root/pipeline.json` |
| `__serving_bucket_name__` | `SERVING_BUCKET_NAME` | `model_promotion_workflow.yaml` | `bucket-data-meuproduto-inf` |
| `__train_service_account__` | `TRAIN_SERVICE_ACCOUNT` | `model-config.yaml` | `sa-vertex-ai-pipeline@...` |
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

1. Escreva `pipelines/pipeline.py` e `src/*.sql` com a lógica do seu modelo.
2. Confira `model-config.yaml` gerado — principalmente os buckets e service accounts, que costumam ter nomes com pequenas variações reais do que está no exemplo.
3. Configure os secrets do repositório novo: `workload_identity_provider_gcp` e `service_account_gcp` (usados por `deploy.yml` para autenticar via Workload Identity Federation).
4. Confirme que os Worker Pools privados (`WORKERPOOL_DEV`/`WORKERPOOL_PROD`) e o Cloud Workflow (`WORKFLOW_NAME`) já existem nos projetos de destino, ou provisione-os antes do primeiro push/tag — este template não os cria, só os referencia.
5. `git push` na branch configurada em `BRANCH_NAME` dispara o job de modelagem; uma tag `v*` dispara o job de inferência/promoção.
