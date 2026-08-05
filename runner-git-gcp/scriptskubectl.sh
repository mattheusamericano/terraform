kubectl get secret secret-app-arc-auth-api -n arc-runners -o yaml \
  | yq 'del(.metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.ownerReferences, .metadata.selfLink, .metadata.namespace)' \
  > secret-app-arc-auth-api.yaml

kubectl get secret interna-caixa -n arc-runners -o yaml \
  | yq 'del(.metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.ownerReferences, .metadata.selfLink, .metadata.namespace)' \
  > interna-caixa.yaml
