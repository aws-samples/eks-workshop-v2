set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  # Clean up secrets lab artifacts
  kubectl delete secretproviderclass catalog-spc -n catalog --ignore-not-found
  kubectl delete externalsecret catalog-external-secret -n catalog --ignore-not-found
  kubectl delete clustersecretstore cluster-secret-store --ignore-not-found 2>/dev/null || true

  # Delete the test secret from Secrets Manager
  if [ -n "${SECRET_NAME:-}" ]; then
    aws secretsmanager delete-secret --secret-id "$SECRET_NAME" --force-delete-without-recovery 2>/dev/null || true
  fi

  # Restore catalog to base state
  kubectl apply -k ~/environment/eks-workshop/base-application/catalog
  kubectl rollout status deployment/catalog -n catalog --timeout=120s

  # Wait for all workshop pods to stabilize before next lab
  sleep 30
  kubectl wait --for=condition=Ready --timeout=300s pods -l app.kubernetes.io/created-by=eks-workshop -A
}

"$@"
