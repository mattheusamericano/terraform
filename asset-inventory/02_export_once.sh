#!/usr/bin/env bash
# Roda a exportação do Cloud Asset Inventory para o BigQuery uma única vez.
# Útil para validar que tudo está configurado antes de agendar.
set -euo pipefail

# ---- ajuste estas variáveis ----
PROJECT_ID="meu-projeto"
ORG_ID="123456789012"
DATASET="asset_inventory"
# ---------------------------------

echo "Exportando RESOURCES (metadados dos recursos)..."
gcloud asset export \
  --organization="${ORG_ID}" \
  --content-type=resource \
  --bigquery-table="projects/${PROJECT_ID}/datasets/${DATASET}/tables/inventory_resources" \
  --partition-key=request-time \
  --output-bigquery-force

echo "Exportando IAM POLICIES (quem tem acesso a quê)..."
gcloud asset export \
  --organization="${ORG_ID}" \
  --content-type=iam-policy \
  --bigquery-table="projects/${PROJECT_ID}/datasets/${DATASET}/tables/inventory_iam_policies" \
  --partition-key=request-time \
  --output-bigquery-force

echo "Exportação concluída. Confira as tabelas em ${PROJECT_ID}:${DATASET}"
echo "Nota: exports de organização podem levar alguns minutos para finalizar."
