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
├── generate.sh                            # opcional: "congela" os valores nos arquivos, numa pasta separada
├── apply-vars.sh                          # motor de substituição comum (usado por generate.sh e pelos jobs de treino)
├── requirements.txt                       # dependências Python (genérico)
├── .gcloudignore                          # genérico, não precisa editar
├── model-config.yaml                      # config declarativa do ciclo de vida do modelo
├── .github/workflows/
│   └── deploy.yml                         # gatilho de CI/CD — sem placeholder, lê vars.env em cada run
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

### Uso recomendado — vars.env resolvido em tempo de execução, sem commit automático

`deploy.yml` **não tem nenhum placeholder** — nunca precisa ser "instanciado". Toda a configuração vem de `vars.env`, lido do zero a cada execução do workflow:
- Um job `load-config` faz checkout, lê `vars.env` e repassa os valores (projetos, região, worker pools, branch) pros outros jobs via `needs.load-config.outputs` — só assim dá pra usar esses valores no `if:`/`env` dos jobs de treino, já que o `if:` de um job é avaliado antes de qualquer step dele rodar.
- Os jobs `train-and-evaluate-mdl`/`train-and-evaluate-inf` rodam `apply-vars.sh vars.env .` logo depois do checkout — isso resolve os placeholders de `model-config.yaml`, `pipeline.py`, os `*.sql` e os defaults de `.cloudbuild/*.yaml` **só no workspace daquele run**, nunca commitado. Na sequência, `gcloud builds submit .` envia esse workspace já resolvido pro Cloud Build.

Ou seja: **nenhum commit automático acontece nunca** — nem para preencher placeholders, nem para "limpar" o template depois. `vars.env` é um arquivo normal e permanente do repositório, do mesmo jeito que `model-config.yaml` já era; editar um valor (trocar projeto, região, etc.) é só um commit seu de `vars.env`, sem precisar rodar nada.

**Passo a passo:**
1. Pelo navegador (ou por onde for mais conveniente — Fusion X, `git`, etc.): crie `vars.env` na raiz do repositório com o conteúdo de `vars.example.env` preenchido com os valores reais.
2. Comite/dê push normalmente. Push numa branch dispara `train-and-evaluate-mdl` se `BRANCH_NAME` (dentro do `vars.env`) bater com a branch do push; uma tag `v*` dispara `train-and-evaluate-inf`. Também dá pra disparar manualmente pela aba **Actions → MLOps Model Training Deployment → Run workflow**.
3. Acompanhe a aba **Actions**.

Não precisa de nenhum secret além dos já existentes (`workload_identity_provider_gcp`, `service_account_gcp`) — como nada é commitado de volta, não existe a restrição do GitHub sobre alterar `.github/workflows/` (essa trava só se aplica quando o próprio Actions tenta dar push num arquivo de workflow; aqui isso nunca acontece).

### Alternativa — "congelar" os valores nos arquivos (`generate.sh`)

Se você preferir não depender de `vars.env` em tempo de execução — por exemplo, pra gerar um repositório com os valores permanentemente escritos nos arquivos, sem esse arquivo de configuração à parte — use `generate.sh` (precisa de terminal com bash, local ou num Cloud Shell/Codespace):

```bash
cp vars.example.env vars.env      # edite vars.env com os dados reais do novo produto
./generate.sh vars.env ../repositorio-do-novo-produto
```

O script copia todos os arquivos deste repositório para `../repositorio-do-novo-produto` e aplica `vars.env` nessa cópia (usando `apply-vars.sh`), removendo `vars.env`/`generate.sh`/`apply-vars.sh`/`vars.example.env`/`README.md` do resultado — o repositório gerado fica com os valores fixos nos arquivos, sem depender de `vars.env` para nada (nesse caso o `deploy.yml` também não precisaria mais do job `load-config`/`apply-vars.sh`, mas o template não remove esses jobs automaticamente — eles só passam a não fazer diferença, já que não há mais placeholder pra resolver). Se sobrar algum placeholder sem preencher, o script termina com erro (código de saída != 0) e mostra exatamente qual arquivo/linha ficou pendente.

## Variáveis (`vars.env`) e placeholders (`__CHAVE__`)

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
| `__train_project_id__` | `TRAIN_PROJECT_ID` | `model-config.yaml`, `pipeline.py` (fallback); lido também em runtime por `deploy.yml` (job `load-config`) | `prj-meuproduto-mdl-prd` |
| `__serving_project_id__` | `SERVING_PROJECT_ID` | `model-config.yaml`, `model_promotion_workflow.yaml`; lido também em runtime por `deploy.yml` (job `load-config`) | `prj-meuproduto-inf-prd` |
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
| — *(sem placeholder — só runtime)* | `BRANCH_NAME` | Lido em runtime por `deploy.yml` (job `load-config`), decide se `train-and-evaluate-mdl` roda naquele push | `meuproduto-model` |
| — *(sem placeholder — só runtime)* | `WORKERPOOL_DEV` | Lido em runtime por `deploy.yml` (job `load-config`) | `workerpool-meuproduto-mdl` |
| — *(sem placeholder — só runtime)* | `WORKERPOOL_PROD` | Lido em runtime por `deploy.yml` (job `load-config`) | `workerpool-meuproduto-inf` |

## Três mecanismos de variável — não confunda os três

1. **Placeholders `__CHAVE__`** (`model-config.yaml`, `.cloudbuild/*.yaml`, `pipeline.py`, `src/*.sql`, `model_promotion_workflow.yaml`): resolvidos pelo `apply-vars.sh` — em runtime, dentro do job de treino, a cada execução (uso recomendado); ou uma única vez, "congelados", se você usar `generate.sh`.
2. **Chaves lidas direto de `vars.env` em runtime** (`BRANCH_NAME`, `WORKERPOOL_DEV`, `WORKERPOOL_PROD`, e também `TRAIN_PROJECT_ID`/`SERVING_PROJECT_ID`/`REGION` no job `load-config`): nunca viram `__PLACEHOLDER__` em arquivo nenhum — `deploy.yml` só faz `source vars.env` e usa o valor na hora.
3. **`substitutions:` do Cloud Build** (dentro de `.cloudbuild/dev.yaml`/`prod.yaml`, ex.: `_REGION`, `_TAG_NAME`): esses `_VAR` do Cloud Build já vêm resolvidos pelo mecanismo 1 (via `apply-vars.sh`) antes do `gcloud builds submit`; a exceção é `_TAG_NAME`, que continua sendo passado por `--substitutions` a cada build (é a tag da release, varia a cada execução, não faz sentido vir de `vars.env`).

## Checklist antes do primeiro push

1. Preencha `vars.env` a partir de `vars.example.env` com os valores reais — confira principalmente buckets e service accounts, que costumam ter nomes com pequenas variações reais do que está no exemplo.
2. Rode o fluxo de ponta a ponta como veio (sem trocar nada em `pipelines/pipeline.py`/`src/*.sql`) contra um projeto de teste — é um pipeline funcional de treino BQML + deploy, serve pra validar que a esteira de CI/CD toda está correta antes de mexer em lógica de modelo.
3. Quando for além do pontapé inicial: troque `src/train_model.sql` (e `evaluate_model.sql`) pela tabela e pelas colunas de features/label do seu modelo real. `pipelines/pipeline.py` (orquestração, deploy, Canary Split) normalmente não precisa mudar.
4. Configure os secrets do repositório: `workload_identity_provider_gcp` e `service_account_gcp` (usados por `deploy.yml` para autenticar via Workload Identity Federation). Não precisa de nenhum secret adicional — nada é commitado automaticamente.
5. Confirme que os Worker Pools privados (`WORKERPOOL_DEV`/`WORKERPOOL_PROD`) e o Cloud Workflow (`WORKFLOW_NAME`) já existem nos projetos de destino, ou provisione-os antes do primeiro push/tag — este template não os cria, só os referencia.
6. Push numa branch cujo nome bate com `BRANCH_NAME` (dentro de `vars.env`) dispara o job de modelagem; uma tag `v*` dispara o job de inferência/promoção.
