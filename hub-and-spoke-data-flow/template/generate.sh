#!/usr/bin/env bash
# ==============================================================================
# generate.sh — instancia este template para um novo produto/projeto,
# copiando os arquivos e substituindo cada __placeholder__ pelo valor
# correspondente definido num arquivo de variáveis (formato CHAVE=valor).
#
# Uso:
#   cp vars.example.env vars.env   # edite vars.env com os dados reais
#   ./generate.sh vars.env ../../meu-novo-produto
#
# Cada CHAVE=valor em vars.env vira __chave_em_minusculo__ no template
# (ex.: REGION=southamerica-east1 substitui __region__ em todos os arquivos).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Uso: $0 <arquivo-de-variaveis> <diretorio-de-saida>" >&2
  echo "Exemplo: $0 vars.env ../../meu-novo-produto" >&2
  exit 1
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

escape_value() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

[ $# -eq 2 ] || usage

VARS_FILE="$1"
OUT_DIR="$2"

if [ ! -f "$VARS_FILE" ]; then
  echo "Erro: arquivo de variáveis não encontrado: $VARS_FILE" >&2
  exit 1
fi

if [ -e "$OUT_DIR" ] && [ -n "$(ls -A "$OUT_DIR" 2>/dev/null)" ]; then
  echo "Erro: diretório de saída já existe e não está vazio: $OUT_DIR" >&2
  echo "Escolha outro diretório ou esvazie este antes de rodar novamente." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
cp -R "$SCRIPT_DIR"/. "$OUT_DIR"/
rm -f "$OUT_DIR/generate.sh" "$OUT_DIR/vars.example.env" "$OUT_DIR/README.md"

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

echo "=== Aplicando variáveis de '$VARS_FILE' em '$OUT_DIR' ==="
find "$OUT_DIR" -type f -print0 | while IFS= read -r -d '' f; do
  sed -i.bak -f "$SED_SCRIPT" "$f"
  rm -f "${f}.bak"
done

echo "=== Verificando se restaram placeholders não preenchidos ==="
# Exclui padrões legítimos que também batem com __algo__ mas não são
# placeholders deste template: dunders do Python (__file__, __main__, ...)
# e __pycache__/.gitignore.
PY_DUNDERS='__pycache__|__init__|__main__|__file__|__name__|__doc__|__dict__|__version__|__all__|__class__|__module__'
if grep -rn '__[a-z0-9_]*__' "$OUT_DIR" 2>/dev/null | grep -v -E "$PY_DUNDERS"; then
  echo ""
  echo "AVISO: os placeholders acima não foram substituídos — confira se todas"
  echo "as chaves usadas no template têm uma linha correspondente em '$VARS_FILE'."
else
  echo "OK — nenhum placeholder __..__ restante."
fi

echo ""
echo "=== Template gerado em: $OUT_DIR ==="
echo "Próximos passos:"
echo "  1. Confira model-config.yaml, .cloudbuild/dev.yaml e .cloudbuild/prod.yaml"
echo "     gerados antes do primeiro push."
echo "  2. pipelines/pipeline.py e src/*.sql já vieram como um pipeline BQML"
echo "     funcional (referência/pontapé inicial) — dá pra rodar como está"
echo "     contra um projeto de teste antes de trocar a lógica do modelo."
echo "  3. Configure os secrets do GitHub: workload_identity_provider_gcp e"
echo "     service_account_gcp."
