#!/usr/bin/env bash
# Instala um crontab na própria VM pra rodar o export do Cloud Asset Inventory
# 1x por semana, sem depender de Cloud Build/Cloud Run/Cloud Scheduler
# (o projeto não tem Cloud Build fora da região US, e não vamos usar pool
# privado só pra isso — essa VM já roda o gcloud autenticado, então usamos
# o cron do próprio Linux).
#
# (nome do arquivo ficou de uma versão anterior que usava Cloud Run — o
# conteúdo abaixo já foi trocado pra crontab local)
set -euo pipefail

# ---- ajuste estas variáveis ----
ORG_ID="61181892930"
PROJECT_ID="terraform-442218" 
DATASET="asset_inventory"
# Dia/hora da execução semanal: toda segunda-feira às 06:00
CRON_SCHEDULE="0 6 * * 1"
# Onde o script e o log vão morar
EXPORT_SCRIPT="${HOME}/export_semanal.sh"
EXPORT_LOG="${HOME}/export_semanal.log"
# ---------------------------------

echo "Criando script de export em ${EXPORT_SCRIPT}..."
cat > "${EXPORT_SCRIPT}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
gcloud asset export \\
  --organization="${ORG_ID}" \\
  --content-type=resource \\
  --bigquery-table="projects/${PROJECT_ID}/datasets/${DATASET}/tables/inventory_resources" \\
  --partition-key=request-time \\
  --output-bigquery-force
EOF
chmod +x "${EXPORT_SCRIPT}"

echo "Testando o export uma vez (pode levar alguns minutos)..."
"${EXPORT_SCRIPT}"

echo "Registrando no crontab (${CRON_SCHEDULE})..."
CRON_LINE="${CRON_SCHEDULE} ${EXPORT_SCRIPT} >> ${EXPORT_LOG} 2>&1"
( crontab -l 2>/dev/null | grep -vF "${EXPORT_SCRIPT}" ; echo "${CRON_LINE}" ) | crontab -

echo ""
echo "Pronto. Crontab atual:"
crontab -l
echo ""
echo "O inventário será exportado toda segunda-feira às 06:00, direto por esta VM."
echo "Requisito: a VM precisa estar ligada nesse horário. Se ela costuma ficar"
echo "desligada, considere trocar isso por Cloud Workflows (sem depender da VM)."
