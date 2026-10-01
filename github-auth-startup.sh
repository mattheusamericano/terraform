#!/bin/bash
set -e

echo "[INFO] Instalando dependências Python..."
pip3 install --upgrade PyJWT cryptography google-cloud-secret-manager

echo "[INFO] Criando helper de credenciais GitHub App..."

cat > ~/.git-credential-gh-app.py <<'EOF'
#!/usr/bin/env python3

import sys
import time
import json
import urllib.request

from google.cloud import secretmanager
from google.api_core.client_options import ClientOptions
import jwt  # PyJWT

# ==================================================
# CONFIGURAÇÕES
# ==================================================
APP_ID = "5139084"
INSTALLATION_ID = "166606234"
PROJECT_ID = "prj-risco-credito-mod-prd"
SECRET_NAME = "githubapp-workbench-auth"
LOCATION = "southamerica-east1"
# ==================================================


def get_secret():
    """
    Recupera a chave privada da GitHub App
    armazenada no Secret Manager regional.
    """
    endpoint = f"secretmanager.{LOCATION}.rep.googleapis.com"

    client = secretmanager.SecretManagerServiceClient(
        client_options=ClientOptions(api_endpoint=endpoint)
    )

    secret_path = (
        f"projects/{PROJECT_ID}"
        f"/locations/{LOCATION}"
        f"/secrets/{SECRET_NAME}"
        f"/versions/latest"
    )

    response = client.access_secret_version(
        request={"name": secret_path}
    )

    return response.payload.data.decode("UTF-8")


def get_token():
    """
    Gera um JWT da GitHub App e troca
    por um Installation Access Token.
    """
    private_key = get_secret()

    payload = {
        "iat": int(time.time()) - 60,
        "exp": int(time.time()) + 600,
        "iss": APP_ID,
    }

    jwt_token = jwt.encode(
        payload,
        private_key,
        algorithm="RS256"
    )

    request = urllib.request.Request(
        f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens",
        headers={
            "Authorization": f"Bearer {jwt_token}",
            "Accept": "application/vnd.github.v3+json",
        },
        method="POST",
    )

    with urllib.request.urlopen(request) as response:
        body = json.loads(response.read().decode())
        return body["token"]


if len(sys.argv) > 1 and sys.argv[1] == "get":
    print("username=x-access-token")
    print(f"password={get_token()}")
EOF

echo "[INFO] Aplicando permissão de execução..."
chmod 700 ~/.git-credential-gh-app.py

echo "[INFO] Configurando Git Credential Helper..."
git config --global credential.helper "~/.git-credential-gh-app.py"

echo "[INFO] Startup Script concluído com sucesso."