#!/bin/bash
set -euo pipefail

# Post-startup script roda como ROOT. Nada de ~ ou --global aqui.
LOG=/var/log/github-app-setup.log
exec > >(tee -a "$LOG") 2>&1
echo "[INFO] $(date -Is) iniciando setup"

# Interpretador do ambiente do Workbench, nao o python3 do root
PY=/opt/conda/bin/python3
[[ -x "$PY" ]] || PY=/usr/bin/python3

echo "[INFO] Instalando dependencias Python..."
"$PY" -m pip install --upgrade PyJWT cryptography google-cloud-secret-manager

HELPER=/opt/git-credential-gh-app.py

echo "[INFO] Criando helper de credenciais GitHub App..."
cat > "$HELPER" <<EOF
#!$PY
EOF

cat >> "$HELPER" <<'EOF'
import os
import sys
import time
import json
import stat
import urllib.request

from google.cloud import secretmanager
from google.api_core.client_options import ClientOptions
import jwt  # PyJWT

# ==================================================
# CONFIGURACOES
# ==================================================
APP_ID = "5139084"
INSTALLATION_ID = "166606234"
PROJECT_ID = "prj-risco-credito-mod-prd"
SECRET_NAME = "githubapp-workbench-auth"
LOCATION = "southamerica-east1"

CACHE_PATH = "/dev/shm/.gh-app-token"
CACHE_TTL = 3000  # 50 min; o token do GitHub vale 60
# ==================================================


def get_secret():
    """Recupera a chave privada da GitHub App no Secret Manager regional."""
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
    response = client.access_secret_version(request={"name": secret_path})
    return response.payload.data.decode("UTF-8")


def mint_token():
    """Gera o JWT da App e troca por um Installation Access Token."""
    private_key = get_secret()

    now = int(time.time())
    payload = {
        "iat": now - 60,
        "exp": now + 540,   # span total 600s: limite maximo do GitHub
        "iss": APP_ID,
    }
    jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

    request = urllib.request.Request(
        f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens",
        headers={
            "Authorization": f"Bearer {jwt_token}",
            "Accept": "application/vnd.github+json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode())["token"]


def get_token():
    """Token cacheado em tmpfs; evita 3 round-trips a cada operacao Git."""
    try:
        age = time.time() - os.stat(CACHE_PATH).st_mtime
        if age < CACHE_TTL:
            with open(CACHE_PATH) as fh:
                cached = fh.read().strip()
            if cached:
                return cached
    except OSError:
        pass

    token = mint_token()
    try:
        fd = os.open(CACHE_PATH, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as fh:
            fh.write(token)
    except OSError:
        pass  # cache e otimizacao, nao requisito
    return token


if len(sys.argv) > 1 and sys.argv[1] == "get":
    try:
        print("username=x-access-token")
        print(f"password={get_token()}")
    except Exception as exc:
        # Sem isso o Git cai no prompt interativo e o erro real some
        print(f"git-credential-gh-app: {exc}", file=sys.stderr)
        sys.exit(1)
EOF

chmod 0755 "$HELPER"

echo "[INFO] Configurando Git Credential Helper (system-wide)..."
git config --system credential."https://github.com".helper "$HELPER"
git config --system credential."https://github.com".useHttpPath false
git config --system url."https://github.com/".insteadOf "git@github.com:"

echo "[INFO] $(date -Is) Startup Script concluido com sucesso."