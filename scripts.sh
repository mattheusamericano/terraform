#!/usr/bin/env bash
# Verifica se a sub-rede/VPC compartilhada está pronta pra acesso 100% privado
# às APIs do Google (Private Google Access + DNS restrito + firewall/rotas).
set -euo pipefail

HOST_PROJECT_ID="prj-network-services-des-cef"
NETWORK_NAME="vpc-negocio-des"
SUBNET_NAME="sub-coenuvem-des"
REGION="southamerica-east1"

echo "### 1) Private Google Access na sub-rede ###"
gcloud compute networks subnets describe "${SUBNET_NAME}" \
  --project="${HOST_PROJECT_ID}" \
  --region="${REGION}" \
  --format="value(privateIpGoogleAccess)"
echo "(precisa ser 'True'. Se vier 'False', é isso que está faltando.)"
echo ""

echo "### 2) Zonas DNS privadas associadas a essa VPC ###"
gcloud dns managed-zones list \
  --project="${HOST_PROJECT_ID}" \
  --filter="visibility=private AND privateVisibilityConfig.networks.networkUrl:${NETWORK_NAME}" \
  --format="table(name,dnsName,visibility)"
echo "(procure uma zona pra 'googleapis.com' apontando pra restricted.googleapis.com / 199.36.153.4-7)"
echo ""

echo "### 3) Rotas customizadas que possam desviar tráfego pro range restrito ###"
gcloud compute routes list \
  --project="${HOST_PROJECT_ID}" \
  --filter="network:${NETWORK_NAME}" \
  --format="table(name,destRange,nextHopGateway,priority)"
echo ""

echo "### 4) Regras de firewall de egress na VPC ###"
gcloud compute firewall-rules list \
  --project="${HOST_PROJECT_ID}" \
  --filter="network:${NETWORK_NAME} AND direction=EGRESS" \
  --format="table(name,destinationRanges.list(),allowed[].map().firewall_rule().list(),priority,disabled)"