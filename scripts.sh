#!/usr/bin/env bash
# Testa o export via Cloud Run Job SEM --partition-key, pra isolar se é essa
# flag que está causando o INVALID_ARGUMENT (e não a política de
# localização). Escreve numa tabela de teste separada, pra não bagunçar a
# tabela real caso dê certo sem partição.
set -euo pipefail

ORG_ID="61181892930"
PROJECT_ID="terraform-442218"
HOST_PROJECT_ID="prj-network-services-des-cef"
NETWORK_NAME="vpc-negocio-des"
SUBNET_NAME="sub-coenuvem-des"
REGION="southamerica-east1"
DATASET="asset_inventory"
TABLE_TESTE="inventory_resources_debug_nopart"
RUNTIME_SA="sa-terraform@${PROJECT_ID}.iam.gserviceaccount.com"
JOB_NAME="asset-export-debug-nopart"
IMAGE="gcr.io/google.com/cloudsdktool/cloud-sdk:slim"

# Sem --partition-key aqui - só isso muda em relação ao teste anterior.
DEBUG_CMD="gcloud asset export --organization=${ORG_ID} --content-type=resource --bigquery-table=projects/${PROJECT_ID}/datasets/${DATASET}/tables/${TABLE_TESTE} --output-bigquery-force --log-http --verbosity=debug 2>&1 | tail -c 8000"

echo "Fazendo deploy do Job de debug (sem partition-key)..."
gcloud run jobs deploy "${JOB_NAME}" \
  --image="${IMAGE}" \
  --command="bash" \
  --args="-c,${DEBUG_CMD}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --service-account="${RUNTIME_SA}" \
  --network="projects/${HOST_PROJECT_ID}/global/networks/${NETWORK_NAME}" \
  --subnet="projects/${HOST_PROJECT_ID}/regions/${REGION}/subnetworks/${SUBNET_NAME}" \
  --vpc-egress=all-traffic \
  --max-retries=0 \
  --task-timeout=300s

echo "Executando e aguardando..."
gcloud run jobs execute "${JOB_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --wait

echo ""
echo "Resultado (SUCCEEDED ou FAILED) apareceu acima."
echo "Pra ver o log completo (request/response), roda:"
echo "  gcloud logging read 'resource.type=cloud_run_job AND resource.labels.job_name=${JOB_NAME}' --project=${PROJECT_ID} --limit=500 --order=asc --format='value(textPayload)' > log_debug_nopart.txt"
echo "  cat log_debug_nopart.txt"