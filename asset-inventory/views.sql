-- Views de inventário sobre as tabelas exportadas pelo Cloud Asset Inventory.
-- Projeto/dataset confirmados via `bq show --schema` em 23/07/2026:
--   terraform-442218:asset_inventory.inventory_resources
--
-- Schema real da tabela (content-type=resource):
--   name             STRING
--   asset_type       STRING
--   resource         RECORD
--     version                  STRING
--     discovery_document_uri   STRING
--     discovery_name           STRING
--     resource_url             STRING
--     parent                   STRING
--     data                     STRING   (JSON serializado do recurso)
--     location                 STRING
--   ancestors        ARRAY<STRING>
--   update_time      TIMESTAMP
--
-- content-type=iam-policy (tabela inventory_iam_policies):
--   name STRING, asset_type STRING, ancestors ARRAY<STRING>,
--   iam_policy RECORD (bindings ARRAY<RECORD(role, members)>), update_time TIMESTAMP

-- 1) Inventário mais recente, já achatado (dedup por último snapshot de cada asset)
CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_inventory_latest` AS
SELECT
  name,
  asset_type,
  ancestors,
  -- projeto é o elemento de ancestors no formato "projects/<id_ou_numero>"
  (SELECT a FROM UNNEST(ancestors) a WHERE a LIKE 'projects/%' LIMIT 1) AS project_ancestor,
  resource.location AS location,
  resource.parent AS parent,
  resource.resource_url AS resource_url,
  JSON_EXTRACT_SCALAR(resource.data, '$.name') AS resource_name,
  JSON_EXTRACT_SCALAR(resource.data, '$.status') AS status,
  resource.data AS resource_data_json,
  update_time
FROM `terraform-442218.asset_inventory.inventory_resources`
QUALIFY ROW_NUMBER() OVER (PARTITION BY name ORDER BY update_time DESC) = 1;

-- 2) Contagem de recursos por projeto, tipo e região — visão rápida de "o que eu tenho"
CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_resources_by_project_type` AS
SELECT
  project_ancestor,
  asset_type,
  location,
  COUNT(*) AS total_recursos
FROM `terraform-442218.asset_inventory.v_inventory_latest`
GROUP BY project_ancestor, asset_type, location
ORDER BY total_recursos DESC;

-- 3) Recursos sem labels obrigatórias (ex.: "owner", "env", "cost-center")
--    Ajuste a lista de labels obrigatórias conforme sua política interna.
--    OBS: nem todo asset_type tem "labels" no JSON (ex.: bindings de IAM, alguns
--    tipos de configuração) — esses aparecem como NULL nas 3 colunas, o que é
--    esperado; filtre por asset_type se quiser focar só em recursos "labeláveis".
CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_untagged_resources` AS
SELECT
  name,
  asset_type,
  project_ancestor,
  location,
  JSON_EXTRACT_SCALAR(resource_data_json, '$.labels.owner') AS label_owner,
  JSON_EXTRACT_SCALAR(resource_data_json, '$.labels.env') AS label_env,
  JSON_EXTRACT_SCALAR(resource_data_json, '$.labels.cost-center') AS label_cost_center,
  update_time
FROM `terraform-442218.asset_inventory.v_inventory_latest`
WHERE
  JSON_EXTRACT_SCALAR(resource_data_json, '$.labels.owner') IS NULL
  OR JSON_EXTRACT_SCALAR(resource_data_json, '$.labels.env') IS NULL
  OR JSON_EXTRACT_SCALAR(resource_data_json, '$.labels.cost-center') IS NULL;

-- 4) "Última vez que o recurso foi usado" — PROXY, não é uso real.
--    O Cloud Asset Inventory só registra a última vez que o METADADO do
--    recurso mudou (update_time), não a última vez que alguém de fato usou
--    a VM/bucket/etc. Isso já ajuda a achar recursos "esquecidos" há muito
--    tempo sem nenhuma alteração de configuração, mas para uso real (última
--    query, última conexão, CPU idle) seria necessário cruzar com:
--      - Cloud Monitoring (métricas de utilização por recurso)
--      - Cloud Logging / Admin Activity logs (última chamada de API)
--      - Recommender API (insights de "recursos ociosos"), export para BigQuery
--    Posso ajudar a montar qualquer uma dessas integrações depois.
CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_ultima_atualizacao_por_recurso` AS
SELECT
  name,
  asset_type,
  project_ancestor,
  location,
  update_time AS ultima_mudanca_metadado,
  DATE_DIFF(CURRENT_DATE(), DATE(update_time), DAY) AS dias_desde_ultima_mudanca
FROM `terraform-442218.asset_inventory.v_inventory_latest`
ORDER BY update_time ASC;

-- 5) Inventário "limpo" de infraestrutura de verdade — sem execuções de job,
--    pipelines/CI-CD, metadados de API/organização e nada de IAM, que só
--    sujam o relatório da equipe de infra. Use esta view (em vez de
--    v_inventory_latest) nos gráficos/tabelas do dashboard de infraestrutura.
--    O que sai daqui não é descartado — vira a view v_inventory_pipelines
--    logo abaixo, como seção separada do dashboard.
CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_inventory_infra` AS
SELECT *
FROM `terraform-442218.asset_inventory.v_inventory_latest`
WHERE asset_type NOT IN (
  -- execuções/pipelines — não são recursos provisionados, são "eventos"
  'aiplatform.googleapis.com/NotebookExecutionJob',
  'datalineage.googleapis.com/Process',
  'dataform.googleapis.com/WorkflowInvocation',
  'dataform.googleapis.com/Repository',

  -- metadados de API/organização — não são recursos de infraestrutura
  'serviceusage.googleapis.com/Service',
  'cloudresourcemanager.googleapis.com/TagBinding'
)
-- todo tipo de IAM fora (service accounts, roles, políticas, etc.)
AND asset_type NOT LIKE 'iam.googleapis.com/%'
-- grupo de Run/Cloud Build/Workflows fora — vira seção própria (v_inventory_pipelines)
-- EXCEÇÃO: WorkerPool de Run e de Cloud Build contam como infraestrutura
-- de verdade (são os workers provisionados, não execuções/pipelines em si)
AND (asset_type NOT LIKE 'run.googleapis.com/%' OR asset_type = 'run.googleapis.com/WorkerPool')
AND (asset_type NOT LIKE 'cloudbuild.googleapis.com/%' OR asset_type = 'cloudbuild.googleapis.com/WorkerPool')
AND asset_type NOT LIKE 'workflows.googleapis.com/%';

-- 5b) Inventário à parte para Run / Execution Job / Build / Workflows —
--     tudo que é execução, pipeline e CI/CD, separado da infra "de verdade".
--     Baseado no levantamento real do seu projeto em 23/07/2026:
--       aiplatform.googleapis.com/NotebookExecutionJob   65.048
--       dataform.googleapis.com/WorkflowInvocation        2.465
--       cloudbuild.googleapis.com/Build                     519
--       run.googleapis.com/Revision                         420
--       run.googleapis.com/Execution                         78
--       run.googleapis.com/Service                           49
--       cloudbuild.googleapis.com/BuildTrigger               11
--       cloudbuild.googleapis.com/GlobalTriggerSettings       7
--       cloudbuild.googleapis.com/Connection                  4
--       run.googleapis.com/Job                                3
--       cloudbuild.googleapis.com/WorkerPool                  3
--       cloudbuild.googleapis.com/Repository                  3
--       workflows.googleapis.com/Workflow                     2
--       run.googleapis.com/WorkerPool                         1
CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_inventory_pipelines` AS
SELECT *
FROM `terraform-442218.asset_inventory.v_inventory_latest`
WHERE
  (
    asset_type LIKE 'run.googleapis.com/%'
    OR asset_type LIKE 'cloudbuild.googleapis.com/%'
    OR asset_type LIKE 'workflows.googleapis.com/%'
    OR asset_type IN (
      'aiplatform.googleapis.com/NotebookExecutionJob',
      'dataform.googleapis.com/WorkflowInvocation'
    )
  )
  -- WorkerPool de Run/Cloud Build fica só na v_inventory_infra, não aqui
  AND asset_type NOT IN (
    'run.googleapis.com/WorkerPool',
    'cloudbuild.googleapis.com/WorkerPool'
  );

-- 6) IAM bindings em formato tabular — "quem tem acesso a quê" de forma
--    consultável. Depende da tabela inventory_iam_policies (export com
--    --content-type=iam-policy, já incluído no 04_cloudrun_privado.sh).
CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_iam_bindings_flat` AS
SELECT
  name AS resource_name,
  asset_type,
  (SELECT a FROM UNNEST(ancestors) a WHERE a LIKE 'projects/%' LIMIT 1) AS project_ancestor,
  binding.role AS role,
  member,
  update_time
FROM `terraform-442218.asset_inventory.inventory_iam_policies`,
  UNNEST(iam_policy.bindings) AS binding,
