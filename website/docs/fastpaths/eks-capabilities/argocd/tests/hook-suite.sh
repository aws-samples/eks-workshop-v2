set -Eeuo pipefail

before() {
  echo "Asserting Argo CD capability is ACTIVE before running Argo CD lab tests..."
  status=$(aws eks describe-capability \
    --cluster-name "$EKS_CLUSTER_AUTO_NAME" \
    --capability-name "$EKS_CAP_ARGOCD_CAPABILITY" \
    --query 'capability.status' --output text)
  if [[ "$status" != "ACTIVE" ]]; then
    echo "Argo CD capability status is '$status', expected ACTIVE" >&2
    exit 1
  fi

  # Argo CD CRDs registered by the capability
  kubectl get crd applications.argoproj.io >/dev/null

  # CodeCommit repo seeded with the catalog manifests
  aws codecommit get-file \
    --repository-name "$EKS_CAP_CODECOMMIT_REPO" \
    --commit-specifier main \
    --file-path catalog/deployment.yaml >/dev/null
}

after() {
  echo "Asserting Argo CD lab end state..."

  # Application exists and is Synced + Healthy
  kubectl wait --for=jsonpath='{.status.sync.status}'=Synced \
    application/catalog -n argocd --timeout=180s
  kubectl wait --for=jsonpath='{.status.health.status}'=Healthy \
    application/catalog -n argocd --timeout=180s

  # Cluster registered as an Argo CD deployment target
  kubectl get secret -n argocd \
    -l argocd.argoproj.io/secret-type=cluster -o name | grep -q .

  # The GitOps update rolled out: running Deployment is scaled to 2 replicas.
  # Poll up to 2 minutes. Argo CD may show Synced+Healthy briefly before the
  # Deployment observably reflects the latest revision.
  for i in $(seq 1 24); do
    replicas=$(kubectl get deployment catalog -n catalog \
      -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
    if [[ "$replicas" == "2" ]]; then
      return 0
    fi
    sleep 5
  done

  echo "catalog replicas is '$replicas', expected the GitOps-updated value of 2" >&2
  exit 1
}

"$@"
