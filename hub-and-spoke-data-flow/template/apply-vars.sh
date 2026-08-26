#!/usr/bin/env bash
# ==============================================================================
# apply-vars.sh — aplica um arquivo de variáveis (formato CHAVE=valor) sobre
# um diretório, substituindo cada __CHAVE_EM_MINUSCULO__ pelo valor
# correspondente em todos os arquivos daquele diretório (recursivo).
#
# Chamado por .github/workflows/deploy.yml a cada execução dos jobs de
# treino, direto no workspace do runner — nunca commitado/dado push.
#
# Uso: apply-vars.sh <arquivo-de-variaveis> <diretorio-alvo>
# Sai com código != 0 se sobrar algum placeholder __..__ não preenchido.
# ==============================================================================
set -euo pipefail

usage() {
  echo "Uso: $0 <arquivo-de-variaveis> <diretorio-alvo>" >&2
  exit 1
}

trim() {
  local s="$1"
  s="${s%$'\r'}"          # remove \r de fim de linha (arquivo salvo com CRLF/Windows)
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

escape_value() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

[ $# -eq 2 ] || usage

VARS_FILE="$1"
TARGET_DIR="$2"

[ -f "$VARS_FILE" ] || { echo "Erro: arquivo de variáveis não encontrado: $VARS_FILE" >&2; exit 1; }
[ -d "$TARGET_DIR" ] || { echo "Erro: diretório alvo não encontrado: $TARGET_DIR" >&2; exit 1; }

SED_SCRIPT="$(mktemp)"
trap 'rm -f "$SED_SCRIPT"' EXIT

while IFS='=' read -r key value || [ -n "$key" ]; do
  key="$(trim "$key")"
  case "$key" in
    ''|'#'*) continue ;;
  esac
  value="$(trim "${value:-}")"
  token="__$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')__"
  escaped_value="$(escape_value "$value")"
  echo "s|${token}|${escaped_value}|g" >>"$SED_SCRIPT"
done <"$VARS_FILE"

# -not -path exclui .git/ (arquivos binários internos do git — sed quebraria
# neles) e __pycache__/.venv, caso existam no diretório alvo.
find "$TARGET_DIR" \
  \( -name .git -o -name __pycache__ -o -name .venv \) -prune -o \
  -type f -print0 | while IFS= read -r -d '' f; do
  sed -i.bak -f "$SED_SCRIPT" "$f"
  rm -f "${f}.bak"
done

echo "=== Verificando se restaram placeholders não preenchidos ==="
# Exclui padrões legítimos que também batem com __ALGO__ mas não são
# placeholders deste template: dunders do Python (__file__, __main__, ...)
# e __pycache__ (.gitignore/.gcloudignore).
PY_DUNDERS='__pycache__|__init__|__main__|__file__|__name__|__doc__|__dict__|__version__|__all__|__class__|__module__'
leftovers="$(grep -rn '__[a-z0-9_]*__' "$TARGET_DIR" \
  --exclude-dir=.git --exclude-dir=__pycache__ --exclude-dir=.venv 2>/dev/null \
  | grep -v -E "$PY_DUNDERS" || true)"
if [ -n "$leftovers" ]; then
  echo "$leftovers"
  echo ""
  echo "AVISO: os placeholders acima não foram substituídos — confira se todas"
  echo "as chaves usadas no template têm uma linha correspondente em '$VARS_FILE'."
  exit 1
fi

echo "OK — nenhum placeholder __..__ restante."
