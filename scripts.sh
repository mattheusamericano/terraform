#!/usr/bin/env bash
# Cria a zona DNS privada que faltava: resolve *.googleapis.com pro VIP
# restrito (199.36.153.4-7), que é o caminho 100% privado exigido dentro
# de um perímetro VPC Service Controls. Sem isso, o tráfego resolve pro
# IP público normal do Google mesmo com Private Google Access ligado.
#
# Precisa de permissão de DNS Admin no projeto host da Shared VPC
# (prj-network-services-des-cef) - se não tiver, manda esse script pro
# time de redes rodar.
set -euo pipefail

HOST_PROJECT_ID="prj-network-services-des-cef"
NETWORK_NAME="vpc-negocio-des"
ZONE_NAME="restricted-googleapis"

echo "Criando a zona DNS privada '${ZONE_NAME}' associada à VPC ${NETWORK_NAME}..."
gcloud dns managed-zones create "${ZONE_NAME}" \
  --project="${HOST_PROJECT_ID}" \
  --description="Resolve *.googleapis.com para o VIP restrito (VPC-SC)" \
  --dns-name="googleapis.com." \
  --visibility=private \
  --networks="${NETWORK_NAME}"

echo "Criando o registro A raiz (googleapis.com -> VIP restrito)..."
gcloud dns record-sets create googleapis.com. \
  --project="${HOST_PROJECT_ID}" \
  --zone="${ZONE_NAME}" \
  --type=A \
  --ttl=300 \
  --rrdatas=199.36.153.4,199.36.153.5,199.36.153.6,199.36.153.7

echo "Criando o registro CNAME wildcard (*.googleapis.com -> googleapis.com)..."
gcloud dns record-sets create "*.googleapis.com." \
  --project="${HOST_PROJECT_ID}" \
  --zone="${ZONE_NAME}" \
  --type=CNAME \
  --ttl=300 \
  --rrdatas="googleapis.com."

echo ""
echo "Pronto. Confirma com:"
echo "  gcloud dns record-sets list --project=${HOST_PROJECT_ID} --zone=${ZONE_NAME}"
echo ""
echo "Depois disso, roda de novo o Job de debug (05_debug_verbosity.sh) pra ver"
echo "se o INVALID_ARGUMENT some."