-- Total de vCPUs em uso na organização inteira, somando todas as
-- instâncias do Compute Engine que aparecem no inventário atual.
-- Extrai o número de vCPUs a partir do nome do machine type
-- (ex.: n2-standard-4 -> 4, custom-8-16384 -> 8).
--
-- OBS: para as famílias "e2-micro/e2-small/e2-medium" (shared-core), o
-- valor real de vCPU dedicada é fracionário - aqui elas contam como 2
-- (o teto de burst), então o total pode ficar levemente superestimado
-- se você tiver muitas instâncias desses tipos.

SELECT
  SUM(
    CASE
      -- custom-N-<memoria>
      WHEN REGEXP_CONTAINS(machine_type, r'^custom-\d+')
        THEN CAST(REGEXP_EXTRACT(machine_type, r'^custom-(\d+)-') AS INT64)
      -- <familia>-standard-N / -highmem-N / -highcpu-N
      WHEN REGEXP_CONTAINS(machine_type, r'-(standard|highmem|highcpu)-\d+$')
        THEN CAST(REGEXP_EXTRACT(machine_type, r'-(?:standard|highmem|highcpu)-(\d+)$') AS INT64)
      -- e2-micro / e2-small / e2-medium (shared-core, teto de burst = 2)
      WHEN machine_type IN ('e2-micro', 'e2-small', 'e2-medium')
        THEN 2
      -- f1-micro / g1-small (shared-core antigos)
      WHEN machine_type = 'f1-micro' THEN 1
      WHEN machine_type = 'g1-small' THEN 1
      ELSE NULL
    END
  ) AS total_vcpus,
  COUNT(*) AS total_instancias,
  COUNTIF(machine_type IS NULL OR NOT (
    REGEXP_CONTAINS(machine_type, r'^custom-\d+')
    OR REGEXP_CONTAINS(machine_type, r'-(standard|highmem|highcpu)-\d+$')
    OR machine_type IN ('e2-micro','e2-small','e2-medium','f1-micro','g1-small')
  )) AS instancias_nao_reconhecidas -- confira essas manualmente, se houver
FROM (
  SELECT
    REGEXP_EXTRACT(JSON_EXTRACT_SCALAR(resource_data_json, '$.machineType'), r'machineTypes/([^/]+)$') AS machine_type
  FROM `terraform-442218.asset_inventory.v_inventory_latest`
  WHERE asset_type = 'compute.googleapis.com/Instance'
    AND JSON_EXTRACT_SCALAR(resource_data_json, '$.status') = 'RUNNING'
);