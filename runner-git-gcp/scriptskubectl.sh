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
