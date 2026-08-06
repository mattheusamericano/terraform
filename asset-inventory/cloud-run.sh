#!/usr/bin/env bash
# Export do Cloud Asset Inventory via Cloud Run Job com Direct VPC egress,
# saindo pela rede interna (vpc-negocio-des / sub-coenuvem-des, Shared VPC
# hospedada em prj-network-services-des-cef). Sem Cloud Build - usa a imagem
# publica do gcloud direto do Google, sem precisar buildar nada.
set -euo pipefail

# ---- ajuste estas variáveis ----
ORG_ID="61181892930"
PROJECT_ID="terraform-442218"          # projeto onde o Job/Scheduler vivem
HOST_PROJECT_ID="prj-network-services-des-cef"  # dono da Shared VPC
NETWORK_NAME="vpc-negocio-des"
SUBNET_NAME="sub-coenuvem-des"
REGION="southamerica-east1"            # ajuste se a sub-rede for de outra região
DATASET="asset_inventory"
TABLE_RESOURCES="inventory_resources"
TABLE_IAM="inventory_iam_policies"
JOB_NAME="asset-export-job"
RUNTIME_SA="sa-terraform@${PROJECT_ID}.iam.gserviceaccount.com"
SCHEDULER_NAME="asset-export-weekly-trigger"
CRON_SCHEDULE="0 6 * * 1"     # toda segunda-feira às 06:00
TIME_ZONE="America/Sao_Paulo"
# Imagem pública do Google, sem build nenhum
IMAGE="gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
# ---------------------------------

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")
RUN_SERVICE_AGENT="service-${PROJECT_NUMBER}@serverless-robot-prod.iam.gserviceaccount.com"

echo "Habilitando APIs necessárias..."
gcloud services enable \
  run.googleapis.com \
  vpcaccess.googleapis.com \
  cloudscheduler.googleapis.com \
  --project="${PROJECT_ID}"

echo ""
echo "############################################################"
echo "ATENÇÃO - permissão que precisa ser concedida no projeto HOST"
echo "da Shared VPC (${HOST_PROJECT_ID}), por quem administra a rede:"
echo ""
echo "gcloud projects add-iam-policy-binding ${HOST_PROJECT_ID} \\"
echo "  --member=\"serviceAccount:${RUN_SERVICE_AGENT}\" \\"
echo "  --role=\"roles/compute.networkUser\" \\"
echo "  --condition=None"
echo ""
echo "Sem isso, o deploy abaixo falha com erro de permissão na sub-rede."
echo "############################################################"
echo ""
read -p "Já rodaram esse comando no projeto host? [s/N] " confirm
if [[ "${confirm}" != "s" && "${confirm}" != "S" ]]; then
  echo "Ok, peça pro time de redes rodar o comando acima e execute este script de novo depois."
  exit 1
fi

# Roda os dois exports (resource + iam-policy) numa única execução do Job.
# Usamos "bash -c" com um comando único (sem vírgulas dentro dele, já que
# --args do Cloud Run separa argumentos por vírgula).
EXPORT_CMD="gcloud asset export --organization=${ORG_ID} --content-type=resource --bigquery-table=projects/${PROJECT_ID}/datasets/${DATASET}/tables/${TABLE_RESOURCES} --partition-key=request-time --output-bigquery-force && gcloud asset export --organization=${ORG_ID} --content-type=iam-policy --bigquery-table=projects/${PROJECT_ID}/datasets/${DATASET}/tables/${TABLE_IAM} --partition-key=request-time --output-bigquery-force"

echo "Fazendo deploy do Cloud Run Job (sem build - imagem pública)..."
gcloud run jobs deploy "${JOB_NAME}" \
  --image="${IMAGE}" \
  --command="bash" \
  --args="-c,${EXPORT_CMD}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --service-account="${RUNTIME_SA}" \
  --network="projects/${HOST_PROJECT_ID}/global/networks/${NETWORK_NAME}" \
  --subnet="projects/${HOST_PROJECT_ID}/regions/${REGION}/subnetworks/${SUBNET_NAME}" \
  --vpc-egress=all-traffic \
  --max-retries=1 \
  --task-timeout=900s

echo "Concedendo roles/run.invoker pra service account rodar o Job via Scheduler..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/run.invoker"

# IMPORTANTE: dentro de um perímetro VPC-SC, o Cloud Scheduler só aceita
# acionar Cloud Run Jobs pelo endpoint v2 da API (não o v1/namespaces antigo).
# https://docs.cloud.google.com/run/docs/execute/jobs-on-schedule-vpc-sc-perimeter
RUN_JOB_URI="https://run.googleapis.com/v2/projects/${PROJECT_ID}/locations/${REGION}/jobs/${JOB_NAME}:run"

echo "Agendando execução semanal (${CRON_SCHEDULE}, ${TIME_ZONE})..."
gcloud scheduler jobs create http "${SCHEDULER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --schedule="${CRON_SCHEDULE}" \
  --time-zone="${TIME_ZONE}" \
  --uri="${RUN_JOB_URI}" \
  --http-method=POST \
  --oauth-service-account-email="${RUNTIME_SA}" \
  || gcloud scheduler jobs update http "${SCHEDULER_NAME}" \
       --project="${PROJECT_ID}" \
       --location="${REGION}" \
       --schedule="${CRON_SCHEDULE}" \
       --time-zone="${TIME_ZONE}" \
       --uri="${RUN_JOB_URI}"

echo ""
echo "Pronto. Pra testar agora, sem esperar a segunda-feira:"
echo "  gcloud run jobs execute ${JOB_NAME} --region=${REGION} --project=${PROJECT_ID}"
