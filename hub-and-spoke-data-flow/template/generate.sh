#!/usr/bin/env bash
# ==============================================================================
# generate.sh — instancia este template para um novo produto/projeto,
# copiando os arquivos pra outra pasta e aplicando as variáveis (via
# apply-vars.sh) nessa cópia.
#
# Fluxo local/manual — precisa de terminal com bash. Se você não tem git/bash
# na sua máquina, veja a Opção 0 ("automática via GitHub") no README.md: dá
# pra fazer tudo isso sem terminal nenhum, direto pelo navegador.
#
# Uso:
#   cp vars.example.env vars.env   # edite vars.env com os dados reais
#   ./generate.sh vars.env ../meu-novo-produto
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Uso: $0 <arquivo-de-variaveis> <diretorio-de-saida>" >&2
  echo "Exemplo: $0 vars.env ../meu-novo-produto" >&2
  exit 1
}

[ $# -eq 2 ] || usage

VARS_FILE="$1"
OUT_DIR="$2"

if [ ! -f "$VARS_FILE" ]; then
  echo "Erro: arquivo de variáveis não encontrado: $VARS_FILE" >&2
  exit 1
fi

if [ -e "$OUT_DIR" ]; then
  # Permite um diretório que só contenha .git/ — é o caso normal de já ter
  # clonado localmente um repositório remoto vazio antes de gerar o template.
  non_git_entries="$(ls -A "$OUT_DIR" 2>/dev/null | grep -v -x '\.git' || true)"
  if [ -n "$non_git_entries" ]; then
    echo "Erro: diretório de saída já existe e não está vazio: $OUT_DIR" >&2
    echo "Escolha outro diretório, ou esvazie-o (exceto .git/) antes de rodar novamente." >&2
    exit 1
  fi
fi

mkdir -p "$OUT_DIR"
cp -R "$SCRIPT_DIR"/. "$OUT_DIR"/
# Remove as ferramentas de instanciação do template — não fazem parte do
# produto final gerado.
rm -f "$OUT_DIR/generate.sh" "$OUT_DIR/apply-vars.sh" "$OUT_DIR/vars.example.env" "$OUT_DIR/README.md"
# Não precisa remover o job "bootstrap-template" de deploy.yml: como não há
# vars.env neste output, aquele job nunca é acionado (fica só inofensivo/sem
# uso) — ver comentário no topo de .github/workflows/deploy.yml.

echo "=== Aplicando variáveis de '$VARS_FILE' em '$OUT_DIR' ==="
"$SCRIPT_DIR/apply-vars.sh" "$VARS_FILE" "$OUT_DIR"

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
