-- Views de inventário sobre as tabelas exportadas pelo Cloud Asset Inventory.
-- Ajuste PROJECT_ID.DATASET conforme seu setup (mesmo do 01_setup_dataset.sh).
--
-- Schema de referência das tabelas exportadas pelo CAI (content-type=resource):
--   name STRING, asset_type STRING, ancestors ARRAY<STRING>,
--   resource RECORD (version, discovery_name, parent, location, data STRING/JSON),
--   update_time TIMESTAMP
-- (content-type=iam-policy):
--   name STRING, asset_type STRING, ancestors ARRAY<STRING>,
--   iam_policy RECORD (bindings ARRAY<RECORD(role, members)>), update_time TIMESTAMP

DECLARE project_dataset STRING DEFAULT 'PROJECT_ID.asset_inventory';

-- 1) Inventário mais recente, já achatado (dedup por último snapshot de cada asset)
CREATE OR REPLACE VIEW `PROJECT_ID.asset_inventory.v_inventory_latest` AS
SELECT
  name,
  asset_type,
  ancestors,
  -- projeto é sempre o penúltimo elemento típico em ancestors (ex: "projects/123")
  (SELECT a FROM UNNEST(ancestors) a WHERE a LIKE 'projects/%' LIMIT 1) AS project_ancestor,
  resource.location AS location,
  resource.parent AS parent,
  JSON_EXTRACT_SCALAR(resource.data, '$.name') AS resource_name,
  JSON_EXTRACT_SCALAR(resource.data, '$.status') AS status,
  update_time
FROM `PROJECT_ID.asset_inventory.inventory_resources`
QUALIFY ROW_NUMBER() OVER (PARTITION BY name ORDER BY update_time DESC) = 1;

-- 2) Contagem de recursos por projeto, tipo e região — visão rápida de "o que eu tenho"
CREATE OR REPLACE VIEW `PROJECT_ID.asset_inventory.v_resources_by_project_type` AS
SELECT
  project_ancestor,
  asset_type,
  location,
  COUNT(*) AS total_recursos
FROM `PROJECT_ID.asset_inventory.v_inventory_latest`
GROUP BY project_ancestor, asset_type, location
ORDER BY total_recursos DESC;

-- 3) Recursos sem labels obrigatórias (ex.: "owner", "env", "cost-center")
--    Ajuste a lista de labels obrigatórias conforme sua política interna.
CREATE OR REPLACE VIEW `PROJECT_ID.asset_inventory.v_untagged_resources` AS
WITH labels AS (
  SELECT
    name,
    asset_type,
    project_ancestor,
    JSON_EXTRACT_SCALAR(resource.data, '$.labels.owner') AS label_owner,
    JSON_EXTRACT_SCALAR(resource.data, '$.labels.env') AS label_env,
    JSON_EXTRACT_SCALAR(resource.data, '$.labels.cost-center') AS label_cost_center
  FROM `PROJECT_ID.asset_inventory.inventory_resources` r
  LEFT JOIN `PROJECT_ID.asset_inventory.v_inventory_latest` v USING (name)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY r.name ORDER BY r.update_time DESC) = 1
)
SELECT *
FROM labels
WHERE label_owner IS NULL OR label_env IS NULL OR label_cost_center IS NULL;

-- 4) IAM bindings em formato tabular — "quem tem acesso a quê" de forma consultável
CREATE OR REPLACE VIEW `PROJECT_ID.asset_inventory.v_iam_bindings_flat` AS
SELECT
  name AS resource_name,
  asset_type,
  binding.role AS role,
  member,
  update_time
FROM `PROJECT_ID.asset_inventory.inventory_iam_policies`,
  UNNEST(iam_policy.bindings) AS binding,
  UNNEST(binding.members) AS member
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY name, binding.role, member ORDER BY update_time DESC
) = 1;

-- 5) (Opcional) Custo por recurso, se você também exportar Billing para BigQuery.
-- Descomente e ajuste os nomes de tabela/coluna do seu billing export.
--
-- CREATE OR REPLACE VIEW `PROJECT_ID.asset_inventory.v_custo_por_recurso` AS
-- SELECT
--   inv.project_ancestor,
--   inv.asset_type,
--   b.sku.description AS sku,
--   SUM(b.cost) AS custo_total
-- FROM `PROJECT_ID.billing_export.gcp_billing_export_v1_XXXXXX` b
-- JOIN `PROJECT_ID.asset_inventory.v_inventory_latest` inv
--   ON b.project.id = REPLACE(inv.project_ancestor, 'projects/', '')
-- GROUP BY 1, 2, 3;
