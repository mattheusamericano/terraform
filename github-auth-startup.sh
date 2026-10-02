#!/bin/bash
set -euo pipefail

LOG=/var/log/github-app-setup.log
exec > >(tee -a "$LOG") 2>&1
echo "[INFO] $(date -Is) iniciando setup"

PY=""
for cand in /opt/micromamba/bin/python3 \
            /opt/conda/bin/python3 \
            /opt/conda/bin/python; do
  if [[ -x "$cand" ]]; then PY="$cand"; break; fi
done

if [[ -z "$PY" ]]; then
  PY="$(sudo -u jupyter bash -lc 'command -v python3' 2>/dev/null || true)"
fi

if [[ -z "$PY" || "$PY" == "/usr/bin/python3" ]]; then
  echo "[ERRO] interpretador do JupyterLab nao encontrado; abortando."
  exit 1
fi
echo "[INFO] interpretador: $PY"

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
import urllib.request

from google.cloud import secretmanager
import jwt

APP_ID = "5139084"
INSTALLATION_ID = "166606234"
PROJECT_ID = "prj-risco-credito-mod-prd"
SECRET_NAME = "githubapp-workbench-auth"

CACHE_PATH = "/dev/shm/.gh-app-token"
CACHE_TTL = 3000


def get_secret():
    client = secretmanager.SecretManagerServiceClient()
    secret_path = f"projects/{PROJECT_ID}/secrets/{SECRET_NAME}/versions/latest"
    response = client.access_secret_version(request={"name": secret_path})
    return response.payload.data.decode("UTF-8")


def mint_token():
    private_key = get_secret()

    now = int(time.time())
    payload = {
        "iat": now - 60,
        "exp": now + 540,
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
    try:
        if time.time() - os.stat(CACHE_PATH).st_mtime < CACHE_TTL:
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
        pass
    return token


if len(sys.argv) > 1 and sys.argv[1] == "get":
    try:
        print("username=x-access-token")
        print(f"password={get_token()}")
    except Exception as exc:
        print(f"git-credential-gh-app: {exc}", file=sys.stderr)
        sys.exit(1)
EOF

chmod 0755 "$HELPER"

if ! "$PY" -c "import jwt, google.cloud.secretmanager" 2>/dev/null; then
  echo "[ERRO] dependencias nao importam em $PY"
  exit 1
fi

echo "[INFO] Configurando Git Credential Helper (system-wide)..."
git config --system credential."https://github.com".helper "$HELPER"
git config --system credential."https://github.com".useHttpPath false
git config --system url."https://github.com/".insteadOf "git@github.com:"
git config --system url."https://github.com/".insteadOf "ssh://git@github.com/"

echo "[INFO] $(date -Is) Startup Script concluido com sucesso."