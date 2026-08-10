kubectl get secret secret-app-arc-auth-api -n arc-runners -o yaml \
  | yq 'del(.metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.ownerReferences, .metadata.selfLink, .metadata.namespace)' \
  > secret-app-arc-auth-api.yaml

kubectl get secret interna-caixa -n arc-runners -o yaml \
  | yq 'del(.metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.ownerReferences, .metadata.selfLink, .metadata.namespace)' \
  > interna-caixa.yaml


gcloud container clusters get-credentials <nome-do-cluster-novo> --region <regiao> --project <projeto>

kubectl create namespace arc-runners --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n arc-runners -f secret-app-arc-auth-api.yaml
kubectl apply -n arc-runners -f interna-caixa.yaml


helm uninstall arc-runner-set-default-gcp-nprod -n arc-runners
helm uninstall arc-runner-set-imgcustom-v1-gcp-nprod -n arc-runners


gcloud asset analyze-iam-policy \
  --organization=ORG_ID \
  --identity="serviceAccount:sa-gke-runner-des@prj-runner-services-des.iam.gserviceaccount.com" \
  --format="table(mainAnalysis.analysisResults[].attachedResourceFullName, mainAnalysis.analysisResults[].iamBinding.role)"

# 1. Pega o ID da conta de billing
gcloud billing accounts list

# 2. Confirma seu papel nela (troque BILLING_ACCOUNT_ID pelo valor do passo 1)
gcloud billing accounts get-iam-policy BILLING_ACCOUNT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:$(gcloud config get-value account)" \
  --format="table(bindings.role)"

  kubectl get pods -n arc-systems -l app.kubernetes.io/component=runner-scale-set-listener

  kubectl logs -n arc-systems <nome-do-pod-listener-default> --tail=100

# 3. Confirma qual projeto está vinculado a essa conta de billing
gcloud billing projects list --billing-account=BILLING_ACCOUNT_ID




helm upgrade arc-runner-set-imgcustom-v1-gcp-nprod \
  --namespace arc-runners \
  --reuse-values \
  --set minRunners=0 \
  --set maxRunners=0 \
  --version 0.12.1 \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

kubectl logs -n arc-systems deploy/arc-gha-rs-controller --tail=200 | grep -i default


  kubectl logs -n arc-systems -l app.kubernetes.io/component=runner-scale-set-listener --tail=100
