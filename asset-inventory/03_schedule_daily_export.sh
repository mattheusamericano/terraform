#!/usr/bin/env bash
# Empacota o export do Cloud Asset Inventory num Cloud Run Job e agenda
# execução diária via Cloud Scheduler, para manter o inventário sempre atualizado.
set -euo pipefail

# ---- ajuste estas variáveis ----
PROJECT_ID="meu-projeto"
ORG_ID="123456789012"
DATASET="asset_inventory"
REGION="southamerica-east1"
SA_NAME="asset-export-runner"
JOB_NAME="asset-export-job"
SCHEDULER_NAME="asset-export-daily"
# ---------------------------------

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Criando service account dedicada..."
gcloud iam service-accounts create "${SA_NAME}" \
  --project="${PROJECT_ID}" \
  --display-name="Executa export diário do Cloud Asset Inventory" || true

gcloud organizations add-iam-policy-binding "${ORG_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudasset.viewer" \
  --condition=None

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/bigquery.jobUser"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/run.invoker"

# Build local mínimo: uma imagem com gcloud CLI que roda o export e sai.
WORKDIR=$(mktemp -d)
cat > "${WORKDIR}/Dockerfile" <<'EOF'
FROM google/cloud-sdk:slim
COPY run_export.sh /run_export.sh
RUN chmod +x /run_export.sh
ENTRYPOINT ["/run_export.sh"]
EOF

cat > "${WORKDIR}/run_export.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
gcloud asset export \\
  --organization="${ORG_ID}" \\
  --content-type=resource \\
  --bigquery-table="projects/${PROJECT_ID}/datasets/${DATASET}/tables/inventory_resources" \\
  --partition-key=request-time \\
  --output-bigquery-force

gcloud asset export \\
  --organization="${ORG_ID}" \\
  --content-type=iam-policy \\
  --bigquery-table="projects/${PROJECT_ID}/datasets/${DATASET}/tables/inventory_iam_policies" \\
  --partition-key=request-time \\
  --output-bigquery-force
EOF

IMAGE="gcr.io/${PROJECT_ID}/asset-export-job"
echo "Buildando imagem ${IMAGE}..."
gcloud builds submit "${WORKDIR}" --tag "${IMAGE}" --project="${PROJECT_ID}"

echo "Criando/atualizando Cloud Run Job..."
gcloud run jobs deploy "${JOB_NAME}" \
  --image="${IMAGE}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --service-account="${SA_EMAIL}" \
  --max-retries=1 \
  --task-timeout=900s

echo "Agendando execução diária às 06:00 (America/Sao_Paulo)..."
gcloud scheduler jobs create http "${SCHEDULER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --schedule="0 6 * * *" \
  --time-zone="America/Sao_Paulo" \
  --uri="https://${REGION}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${PROJECT_ID}/jobs/${JOB_NAME}:run" \
  --http-method=POST \
  --oauth-service-account-email="${SA_EMAIL}" \
  || gcloud scheduler jobs update http "${SCHEDULER_NAME}" \
       --project="${PROJECT_ID}" \
       --location="${REGION}" \
       --schedule="0 6 * * *" \
       --time-zone="America/Sao_Paulo"

rm -rf "${WORKDIR}"
echo "Pronto. O inventário será exportado todo dia às 06:00."
