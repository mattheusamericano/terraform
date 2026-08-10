SELECT asset_type, COUNT(*) AS total
FROM `terraform-442218.asset_inventory.v_inventory_latest`
WHERE
  asset_type LIKE 'run.googleapis.com/%'
  OR asset_type LIKE 'cloudbuild.googleapis.com/%'
  OR asset_type LIKE '%ExecutionJob%'
  OR asset_type LIKE '%WorkflowInvocation%'
  OR asset_type LIKE 'workflows.googleapis.com/%'
  OR asset_type LIKE '%Build%'
GROUP BY asset_type
ORDER BY total DESC;