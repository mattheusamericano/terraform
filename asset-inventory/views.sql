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
-- Escopo definido: só recurso de infra (content-type=resource). IAM fica de
-- fora por enquanto — se precisar depois, é só rodar o export de iam-policy
-- e reativar a view v_iam_bindings_flat que foi removida daqui.

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

-- 5) (Opcional) Custo por recurso, se você também exportar Billing para BigQuery.
-- Descomente e ajuste os nomes de tabela/coluna do seu billing export.
--
-- CREATE OR REPLACE VIEW `terraform-442218.asset_inventory.v_custo_por_recurso` AS
-- SELECT
--   inv.project_ancestor,
--   inv.asset_type,
--   b.sku.description AS sku,
--   SUM(b.cost) AS custo_total
-- FROM `terraform-442218.billing_export.gcp_billing_export_v1_XXXXXX` b
-- JOIN `terraform-442218.asset_inventory.v_inventory_latest` inv
--   ON b.project.id = REPLACE(inv.project_ancestor, 'projects/', '')
-- GROUP BY 1, 2, 3;