#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="SEU_PROJETO"
REGION="us-central1"              # região do Developer Connect
CONNECTION_NAME="github-enterprise-cloud-conn"
GHEC_ORG="sua-org-github"
GHEC_REPO="seu-repo"
DATAFORM_REPO_ID="meu-repositorio-dataform"
DEFAULT_BRANCH="main"

# 1. Habilitar a API
gcloud services enable developerconnect.googleapis.com --project="$PROJECT_ID"

# 2. Criar a service identity do Developer Connect
gcloud beta services identity create \
  --service=developerconnect.googleapis.com \
  --project="$PROJECT_ID"

# 3. IAM necessário (Secret Manager Admin na service agent do Developer Connect,
#    e no service agent do Dataform: Token Accessor + Git Proxy User)
DC_SA="service-$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')@gcp-sa-devconnect.iam.gserviceaccount.com"
DF_SA="service-$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')@gcp-sa-dataform.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${DC_SA}" \
  --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${DF_SA}" \
  --role="roles/developerconnect.tokenAccessor"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${DF_SA}" \
  --role="roles/developerconnect.gitProxyUser"

# 4. Criar a conexão (GitHub "normal" cobre GHEC padrão — sem residência de dados)
#    APP_TYPE aceita: FIREBASE | DATAFORM | GEMINI_CODE_ASSIST | DEVELOPER_CONNECT
gcloud developer-connect connections create "$CONNECTION_NAME" \
  --location="$REGION" \
  --project="$PROJECT_ID" \
  --github-config-app=DATAFORM \
  --git-proxy-config-enabled

# 5. Pegar o link de instalação do GitHub App (precisa autorização humana uma única vez)
gcloud developer-connect connections describe "$CONNECTION_NAME" \
  --location="$REGION" --project="$PROJECT_ID" \
  --format="value(installationState.actionUri)"
# → abrir esse link no navegador e autorizar o app na org $GHEC_ORG

# 6. Confirmar que ficou COMPLETE
gcloud developer-connect connections describe "$CONNECTION_NAME" \
  --location="$REGION" --project="$PROJECT_ID" \
  --format="value(installationState.stage)"

# 7. Criar o git-repository-link apontando pro repo do GHEC
gcloud developer-connect connections git-repository-links create "$GHEC_REPO" \
  --connection="$CONNECTION_NAME" \
  --location="$REGION" --project="$PROJECT_ID" \
  --clone-uri="https://github.com/${GHEC_ORG}/${GHEC_REPO}.git"

# 8. Vincular esse git-repository-link ao repositório Dataform via API REST
#    (o campo gitRemoteSettings.gitRepositoryLink ainda não tem flag no gcloud)
LINK_RESOURCE="projects/${PROJECT_ID}/locations/${REGION}/connections/${CONNECTION_NAME}/gitRepositoryLinks/${GHEC_REPO}"

curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://dataform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/repositories/${DATAFORM_REPO_ID}?updateMask=gitRemoteSettings" \
  -d @- <<EOF
{
  "gitRemoteSettings": {
    "url": "https://github.com/${GHEC_ORG}/${GHEC_REPO}.git",
    "defaultBranch": "${DEFAULT_BRANCH}",
    "gitRepositoryLink": "${LINK_RESOURCE}"
  }
}
EOF