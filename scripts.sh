#!/usr/bin/env bash
# Job temporário só pra diagnosticar o INVALID_ARGUMENT do asset-export-job.
# Mesma config de rede do Job real, mas roda só o export de resource com
# --verbosity=debug, pra capturar a requisição/resposta HTTP completa que o
# gcloud faz por baixo dos panos - o stderr "normal" não mostra isso.
set -euo pipefail

ORG_ID="61181892930"
PROJECT_ID="terraform-442218"
HOST_PROJECT_ID="prj-network-services-des-cef"
NETWORK_NAME="vpc-negocio-des"
SUBNET_NAME="sub-coenuvem-des"
REGION="southamerica-east1"
DATASET="asset_inventory"
TABLE_RESOURCES="inventory_resources"
RUNTIME_SA="sa-terraform@${PROJECT_ID}.iam.gserviceaccount.com"
JOB_NAME="asset-export-debug"
IMAGE="gcr.io/google.com/cloudsdktool/cloud-sdk:slim"

# --log-http é o que de fato despeja o corpo da requisição/resposta (o
# --verbosity=debug sozinho só mostra os logs internos de conexão, sem body).
# tail -c 8000 pra caber o JSON completo sem estourar limite de log.
DEBUG_CMD="gcloud asset export --organization=${ORG_ID} --content-type=resource --bigquery-table=projects/${PROJECT_ID}/datasets/${DATASET}/tables/${TABLE_RESOURCES} --partition-key=request-time --output-bigquery-force --log-http --verbosity=debug 2>&1 | tail -c 8000"

echo "Fazendo deploy do Job de debug..."
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
echo "Pronto. Agora veja o log completo com:"
echo "  gcloud logging read 'resource.type=cloud_run_job AND resource.labels.job_name=${JOB_NAME}' --project=${PROJECT_ID} --limit=200 --format='value(textPayload)' --order=asc"