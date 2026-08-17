-- Uma linha por instância (não pré-somado), pra permitir filtro por
-- projeto no Looker Studio. O Looker Studio faz a soma (SUM) de "vcpus"
-- automaticamente quando você usa um Scorecard/Tabela + filtro.
--
-- OBS mesma observação da query anterior: e2-micro/small/medium contam
-- como 2 vCPUs (teto de burst, shared-core).

SELECT
  project_ancestor,
  name AS instance_name,
  location,
  machine_type,
  CASE
    WHEN REGEXP_CONTAINS(machine_type, r'^custom-\d+')
      THEN CAST(REGEXP_EXTRACT(machine_type, r'^custom-(\d+)-') AS INT64)
    WHEN REGEXP_CONTAINS(machine_type, r'-(standard|highmem|highcpu)-\d+$')
      THEN CAST(REGEXP_EXTRACT(machine_type, r'-(?:standard|highmem|highcpu)-(\d+)$') AS INT64)
    WHEN machine_type IN ('e2-micro', 'e2-small', 'e2-medium') THEN 2
    WHEN machine_type IN ('f1-micro', 'g1-small') THEN 1
    ELSE NULL
  END AS vcpus,
  status
FROM (
  SELECT
    project_ancestor,
    name,
    location,
    JSON_EXTRACT_SCALAR(resource_data_json, '$.status') AS status,
    REGEXP_EXTRACT(JSON_EXTRACT_SCALAR(resource_data_json, '$.machineType'), r'machineTypes/([^/]+)$') AS machine_type
  FROM `terraform-442218.asset_inventory.v_inventory_latest`
  WHERE asset_type = 'compute.googleapis.com/Instance'
)
WHERE status = 'RUNNING';