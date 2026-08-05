
#!/bin/bash

if [ -z "$1" ]; then
  echo "Uso: $0 [prod|nprod] [custom|default|all|controller]"
  exit 1
fi

ENV=$1
TARGET=$2
GITHUB_CONFIG_URL="https://github.com/__gitHubOrg__"
CHART_REPO="oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set"
CHART_VERSION="0.12.1"
CONTROLLER_CHART_REPO="oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller"
CERT_LITERAL="./AC_Interna_Caixa.cer"

ensure_namespace_exists() {
  local namespace="arc-runners"
  if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
    echo "📦 Namespace '$namespace' não existe. Criando..."
    kubectl create namespace "$namespace"
  fi
}

ensure_secret_exists() {
  # Cria a secret interna-caixa somente no default/all
  local namespace="arc-runners"
  local secret_name="interna-caixa"

  ensure_namespace_exists "$namespace"

  if kubectl get secret "$secret_name" -n "$namespace" >/dev/null 2>&1; then
    echo "✅ Secret '$secret_name' já existe no namespace '$namespace'"
    return 0
  fi

  echo "🔐 Secret '$secret_name' não existe no namespace '$namespace'. Criando..."

  if [ -n "$CERT_FILE" ] && [ -f "$CERT_FILE" ]; then
    # Garante o nome do arquivo montado como ca.crt
    kubectl create secret generic "$secret_name" \
      --from-file=ca.crt="$CERT_FILE" \
      -n "$namespace"
    if [ $? -eq 0 ]; then
      echo "✅ Secret '$secret_name' criada a partir do arquivo: $CERT_FILE"
      return 0
    else
      echo "❌ Falha ao criar a secret a partir de arquivo."
      return 1
    fi
  elif [ -n "$CERT_LITERAL" ]; then
    # Fallback: conteúdo literal
    kubectl create secret generic "$secret_name" \
      --from-literal=ca.crt="$CERT_LITERAL" \
      -n "$namespace"
    if [ $? -eq 0 ]; then
      echo "✅ Secret '$secret_name' criada a partir de conteúdo literal"
      return 0
    else
      echo "❌ Falha ao criar a secret a partir de literal."
      return 1
    fi
  else
    echo "❌ Não foi possível criar a secret: defina CERT_FILE (arquivo existente) ou CERT_LITERAL (conteúdo do certificado)."
    return 1
  fi
}


# Função para verificar se o controller existe
check_controller_exists() {
  local namespace="arc-systems"
  if helm list -n "$namespace" | grep -q "arc"; then
    echo "✅ Controller 'arc' encontrado no namespace $namespace"
    return 0
  else
    echo "❌ Controller 'arc' não encontrado no namespace $namespace"
    return 1
  fi
}

# Função para verificar o status do controller
check_controller_health() {
  local namespace="arc-systems"
  echo "🔍 Verificando saúde do controller..."

  # Verificar status do deployment
  local deployment_status
  deployment_status=$(kubectl get deployment -n "$namespace" -o jsonpath='{.items[0].status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
  if [ "$deployment_status" != "True" ]; then
    echo "❌ Deployment do controller não está Available"
    return 1
  fi

  # Verificar se pods estão rodando
  local pod_status
  pod_status=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].status.phase}' 2>/dev/null)
  for status in $pod_status; do
    if [ "$status" != "Running" ]; then
      echo "❌ Pod do controller não está Running (status: $status)"
      return 1
    fi
  done

  # Verificar se pods estão ready
  local ready_pods
  ready_pods=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  for ready in $ready_pods; do
    if [ "$ready" != "True" ]; then
      echo "❌ Pod do controller não está Ready"
      return 1
    fi
  done

  echo "✅ Controller está saudável (Running e Ready)"
  return 0
}

# Função para instalar/atualizar o controller
install_controller() {
  local namespace="arc-systems"
  echo "🎛️ Instalando/Atualizando Actions Runner Controller..."

  # Criar arquivo temporário com values para tolerations
  cat > /tmp/controller-values.yaml << EOF
tolerations:
  - key: "nuvem.caixa/nodepoolname"
    operator: "Equal"
    value: "apprungit"
    effect: "NoSchedule"
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"
EOF

  helm upgrade --install arc \
    --namespace "${namespace}" \
    --create-namespace \
    --version "${CHART_VERSION}" \
    -f /tmp/controller-values.yaml \
    "${CONTROLLER_CHART_REPO}"

  if [ $? -eq 0 ]; then
    echo "✅ Controller instalado/atualizado com sucesso!"

    # Aguardar pods ficarem prontos
    echo "⏳ Aguardando controller ficar pronto..."
    kubectl wait --for=condition=Available deployment --all -n "$namespace" --timeout=300s
    kubectl wait --for=condition=Ready pod --all -n "$namespace" --timeout=300s

    # Limpar arquivo temporário
    rm -f /tmp/controller-values.yaml

    return 0
  else
    echo "❌ Falha na instalação/atualização do controller"
    rm -f /tmp/controller-values.yaml
    exit 1
  fi
}

# Verificar se deve instalar apenas o controller
if [ "$TARGET" == "controller" ]; then
  echo "🎛️ Modo: Instalação/Atualização do Controller apenas"
  install_controller
  exit 0
fi

# Verificar se o controller existe e está saudável
if check_controller_exists; then
  if ! check_controller_health; then
    echo "⚠️ Controller existe mas não está saudável. Reinstalando..."
    install_controller
  else
    echo "✅ Controller existe e está saudável"
  fi
else
  echo "⚠️ Controller não encontrado. Instalando..."
  install_controller
fi

if [ "$ENV" == "prod" ]; then
  echo "Realizando deploy para ambiente de PRODUÇÃO..."
  NAMESPACE="arc-runners"

  if [ "$TARGET" == "custom" ] || [ "$TARGET" == "all" ]; then
    echo "→ Atualizando runner CUSTOM..."
    INSTALLATION_NAME_custom="arc-runner-set-imgcustom-v1-__cloudProvider__-prod"
    VALUES_FILE_custom="__Build.SourcesDirectory__/arc-iac-settings/arc-set-values-runner-custom.yaml"

    helm upgrade --install "${INSTALLATION_NAME_custom}" \
      --namespace "${NAMESPACE}" \
      --create-namespace \
      --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
      -f "${VALUES_FILE_custom}" \
      --version "${CHART_VERSION}" \
      "${CHART_REPO}"
  fi

  if [ "$TARGET" == "default" ] || [ "$TARGET" == "all" ]; then
    echo "→ Validando/criando Secret 'interna-caixa' para DEFAULT..."
    ensure_secret_exists "$NAMESPACE" || exit 1

    echo "→ Atualizando runner DEFAULT..."
    INSTALLATION_NAME_default="arc-runner-set-default-__cloudProvider__-prod"
    VALUES_FILE_default="__Build.SourcesDirectory__/arc-iac-settings/arc-set-values-runner-default.yaml"

    helm upgrade --install "${INSTALLATION_NAME_default}" \
      --namespace "${NAMESPACE}" \
      --create-namespace \
      --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
      -f "${VALUES_FILE_default}" \
      --version "${CHART_VERSION}" \
      "${CHART_REPO}"
  fi

elif [ "$ENV" == "nprod" ]; then

  NAMESPACE="arc-runners"

  if [ "$TARGET" == "custom" ] || [ "$TARGET" == "all" ]; then
    echo "→ Atualizando runner CUSTOM..."
    INSTALLATION_NAME_custom="arc-runner-set-imgcustom-v1-__cloudProvider__-nprod"
    VALUES_FILE_custom="__Build.SourcesDirectory__/arc-iac-settings/arc-set-values-runner-custom.yaml"

    helm upgrade --install "${INSTALLATION_NAME_custom}" \
      --namespace "${NAMESPACE}" \
      --create-namespace \
      --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
      -f "${VALUES_FILE_custom}" \
      --version "${CHART_VERSION}" \
      "${CHART_REPO}"
  fi

  if [ "$TARGET" == "default" ] || [ "$TARGET" == "all" ]; then
    echo "→ Validando/criando Secret 'interna-caixa' para DEFAULT..."
    ensure_secret_exists "$NAMESPACE" || exit 1

    echo "→ Atualizando runner DEFAULT..."
    INSTALLATION_NAME_default="arc-runner-set-default-__cloudProvider__-nprod"
    VALUES_FILE_default="__Build.SourcesDirectory__/arc-iac-settings/arc-set-values-runner-default.yaml"

    helm upgrade --install "${INSTALLATION_NAME_default}" \
      --namespace "${NAMESPACE}" \
      --create-namespace \
      --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
      -f "${VALUES_FILE_default}" \
      --version "${CHART_VERSION}" \
      "${CHART_REPO}"
  fi

else
  echo "Ambiente inválido. Use 'prod' ou 'nprod'."
  exit 1
fi
