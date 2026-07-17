#!/usr/bin/env bash
# Cria o dataset no BigQuery e concede as permissões necessárias
# para o Cloud Asset Inventory conseguir exportar dados nele.
set -euo pipefail

# ---- ajuste estas variáveis ----
PROJECT_ID="meu-projeto"          # projeto onde o BigQuery vai viver
ORG_ID="123456789012"             # ID da organização a ser inventariada
DATASET="asset_inventory"
LOCATION="US"                     # ou "southamerica-east1", etc.
# ---------------------------------

echo "Habilitando APIs necessárias..."
gcloud services enable \
  cloudasset.googleapis.com \
  bigquery.googleapis.com \
  run.googleapis.com \
  cloudscheduler.googleapis.com \
  --project="${PROJECT_ID}"

echo "Criando dataset ${DATASET} no BigQuery..."
bq --project_id="${PROJECT_ID}" mk \
  --dataset \
  --location="${LOCATION}" \
  --description "Inventário de assets GCP via Cloud Asset Inventory" \
  "${PROJECT_ID}:${DATASET}" || echo "Dataset já existe, seguindo..."

# Service Agent do Cloud Asset Inventory precisa poder escrever no BigQuery
CAI_SERVICE_AGENT="service-org-${ORG_ID}@gcp-sa-cloudasset.iam.gserviceaccount.com"

echo "Concedendo bigquery.dataEditor ao service agent do Cloud Asset Inventory..."
bq add-iam-policy-binding \
  --member="serviceAccount:${CAI_SERVICE_AGENT}" \
  --role="roles/bigquery.dataEditor" \
  "${PROJECT_ID}:${DATASET}" 2>/dev/null || \
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${CAI_SERVICE_AGENT}" \
  --role="roles/bigquery.dataEditor"

echo "Concedendo cloudasset.viewer na organização ao service agent (se ainda não tiver)..."
gcloud organizations add-iam-policy-binding "${ORG_ID}" \
  --member="serviceAccount:${CAI_SERVICE_AGENT}" \
  --role="roles/cloudasset.viewer" \
  --condition=None || true

echo "Setup concluído. Dataset: ${PROJECT_ID}:${DATASET}"
