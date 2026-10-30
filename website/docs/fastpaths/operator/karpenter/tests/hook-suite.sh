set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  # Clean up inflate deployment from karpenter lab
  kubectl delete deployment inflate -n other --ignore-not-found

  # Wait for Karpenter consolidation to settle and pods to stabilize
  # Retry the wait since pods may be evicted during consolidation
  sleep 120
  for i in $(seq 1 3); do
    if kubectl wait --for=condition=Ready --timeout=120s pods -l app.kubernetes.io/created-by=eks-workshop -A 2>/dev/null; then
      echo "All pods ready"
      return 0
    fi
    echo "Attempt $i: some pods not ready, waiting for consolidation..."
    sleep 30
  done
  # Final attempt without error suppression
  kubectl wait --for=condition=Ready --timeout=120s pods -l app.kubernetes.io/created-by=eks-workshop -A
}

"$@"
