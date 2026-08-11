#!/usr/bin/env bash
# Agenda o export do Cloud Asset Inventory usando a VM (vm-tf-teste), que já
# funciona sem nenhum ajuste extra de rede/política. Em vez de Cloud Run:
#   1) Um "Instance Schedule" nativo do Compute Engine liga a VM 1x por
#      semana no horário definido.
#   2) Um startup-script (roda toda vez que a VM liga) executa os exports
#      (resource + iam-policy) e no final desliga a própria VM.
#
# Não depende de Cloud Build, Cloud Run, Direct VPC egress nem de nenhuma
# política de localização de recurso serverless - é a mesma VM/rede que já
# está comprovadamente funcionando.
set -euo pipefail

# ---- ajuste estas variáveis ----
ORG_ID="61181892930"
PROJECT_ID="terraform-442218"
VM_NAME="gctfprapllx01"
DATASET="asset_inventory"
TABLE_RESOURCES="inventory_resources"
TABLE_IAM="inventory_iam_policies"
SCHEDULE_NAME="asset-export-weekly-schedule"
CRON_START="0 6 * * 1"          # toda segunda-feira às 06:00 - horário de LIGAR a VM
TIME_ZONE="America/Sao_Paulo"
# ---------------------------------

echo "Localizando a zona da VM '${VM_NAME}'..."
ZONE=$(gcloud compute instances list \
  --project="${PROJECT_ID}" \
  --filter="name=${VM_NAME}" \
  --format="value(zone.basename())")

if [[ -z "${ZONE}" ]]; then
  echo "Não encontrei a VM '${VM_NAME}' no projeto '${PROJECT_ID}'. Confere o nome/projeto."
  exit 1
fi
echo "VM encontrada na zona: ${ZONE}"

echo "Montando o startup-script..."
cat > startup_script_export.sh <<EOF
#!/usr/bin/env bash
# Roda toda vez que a VM liga. Executa os exports e desliga a VM no final,
# então não fica cobrando nem ocupando recurso à toa.
set -x

gcloud asset export --organization=${ORG_ID} --content-type=resource \\
  --bigquery-table=projects/${PROJECT_ID}/datasets/${DATASET}/tables/${TABLE_RESOURCES} \\
  --partition-key=request-time --output-bigquery-force

gcloud asset export --organization=${ORG_ID} --content-type=iam-policy \\
  --bigquery-table=projects/${PROJECT_ID}/datasets/${DATASET}/tables/${TABLE_IAM} \\
  --partition-key=request-time --output-bigquery-force

# Desliga a própria VM ao terminar (comportamento padrão do GCE: shutdown
# dentro do guest OS já para a instância de verdade, sem custo de cobrança).
shutdown -h now
EOF

echo "Anexando o startup-script na VM..."
gcloud compute instances add-metadata "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" \
  --metadata-from-file=startup-script=startup_script_export.sh

echo "Criando o Instance Schedule (liga a VM ${CRON_START}, fuso ${TIME_ZONE})..."
if gcloud compute resource-policies describe "${SCHEDULE_NAME}" \
     --project="${PROJECT_ID}" \
     --region="${ZONE%-*}" \
     >/dev/null 2>&1; then
  echo "Schedule '${SCHEDULE_NAME}' já existe - pulando criação (edite manualmente se precisar mudar o horário)."
else
  gcloud compute resource-policies create instance-schedule "${SCHEDULE_NAME}" \
    --project="${PROJECT_ID}" \
    --region="${ZONE%-*}" \
    --vm-start-schedule="${CRON_START}" \
    --timezone="${TIME_ZONE}" \
    --description="Liga a VM ${VM_NAME} 1x por semana pra rodar o export do Cloud Asset Inventory"
fi

echo "Associando o schedule à VM..."
gcloud compute instances add-resource-policies "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" \
  --resource-policies="${SCHEDULE_NAME}" || echo "(já estava associado - ok)"

echo ""
echo "Pronto. A VM ${VM_NAME} vai ligar sozinha toda segunda às 06:00"
echo "(${TIME_ZONE}), rodar os dois exports e se desligar no final."
echo ""
echo "Pra testar agora sem esperar segunda-feira, liga a VM na mão:"
echo "  gcloud compute instances start ${VM_NAME} --project=${PROJECT_ID} --zone=${ZONE}"
echo "O startup-script roda automaticamente assim que ela ligar."