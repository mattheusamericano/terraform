#!/usr/bin/env bash
# Agenda o export do Cloud Asset Inventory 1x por semana usando
# Cloud Scheduler -> Cloud Workflows. Sem VM, sem Cloud Build, sem container.
#
# (nome do arquivo ficou de versões anteriores que tentaram Cloud Run - o
# conteúdo abaixo já foi trocado pra Workflows, que não depende da VM estar
# ligada e não usa Cloud Build em nenhuma etapa)
set -euo pipefail

# ---- ajuste estas variáveis ----
ORG_ID="61181892930"
PROJECT_ID="terraform-442218"
REGION="southamerica-east1"
SA_NAME="asset-export-workflow"
WORKFLOW_NAME="asset-export-weekly"
SCHEDULER_NAME="asset-export-weekly-trigger"
CRON_SCHEDULE="0 6 * * 1"   # toda segunda-feira às 06:00
TIME_ZONE="America/Sao_Paulo"
WORKFLOW_FILE="workflow_export_semanal.yaml"
# ---------------------------------

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Habilitando APIs necessárias (Workflows e Scheduler)..."
gcloud services enable \
  workflows.googleapis.com \
  workflowexecutions.googleapis.com \
  cloudscheduler.googleapis.com \
  --project="${PROJECT_ID}"

echo "Criando service account dedicada (se não existir)..."
gcloud iam service-accounts create "${SA_NAME}" \
  --project="${PROJECT_ID}" \
  --display-name="Executa o Workflow de export semanal do Cloud Asset Inventory" || true

echo "Concedendo cloudasset.viewer na organização (necessário pra chamar exportAssets)..."
gcloud organizations add-iam-policy-binding "${ORG_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudasset.viewer" \
  --condition=None

echo "Concedendo workflows.invoker no projeto (necessário pro Cloud Scheduler disparar o Workflow)..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/workflows.invoker"

echo "Fazendo deploy do Workflow (${WORKFLOW_FILE})..."
gcloud workflows deploy "${WORKFLOW_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --source="${WORKFLOW_FILE}" \
  --service-account="${SA_EMAIL}"

echo "Agendando execução semanal (${CRON_SCHEDULE}, ${TIME_ZONE})..."
WORKFLOW_EXEC_URL="https://workflowexecutions.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/workflows/${WORKFLOW_NAME}/executions"

gcloud scheduler jobs create http "${SCHEDULER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --schedule="${CRON_SCHEDULE}" \
  --time-zone="${TIME_ZONE}" \
  --uri="${WORKFLOW_EXEC_URL}" \
  --http-method=POST \
  --oauth-service-account-email="${SA_EMAIL}" \
  || gcloud scheduler jobs update http "${SCHEDULER_NAME}" \
       --project="${PROJECT_ID}" \
       --location="${REGION}" \
       --schedule="${CRON_SCHEDULE}" \
       --time-zone="${TIME_ZONE}"

echo ""
echo "Pronto. O Workflow ${WORKFLOW_NAME} roda toda segunda-feira às 06:00,"
echo "disparado pelo Cloud Scheduler, sem depender de nenhuma VM ligada."
echo ""
echo "Pra testar manualmente agora (sem esperar segunda-feira):"
echo "  gcloud workflows run ${WORKFLOW_NAME} --project=${PROJECT_ID} --location=${REGION}"
