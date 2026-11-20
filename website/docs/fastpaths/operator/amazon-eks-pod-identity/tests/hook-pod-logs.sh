set -Eeuo pipefail

debug() {
  echo "=== DEBUG: Checking carts pods ==="
  kubectl get pods -n carts -l app.kubernetes.io/component=service -o wide 2>&1 || true
  echo "=== DEBUG: Carts configmap ==="
  kubectl -n carts get cm carts -o jsonpath='{.data}' 2>&1 || true
  echo ""
  echo "=== DEBUG: Pod identity associations ==="
  aws eks list-pod-identity-associations --cluster-name "${EKS_CLUSTER_AUTO_NAME}" --namespace carts 2>&1 || true
  kubectl describe pods -n carts -l app.kubernetes.io/component=service 2>&1 | tail -30 || true
}

# The page runs `kubectl logs -p` on the latest carts pod, which only works
# once that pod's container has crashed and restarted at least once. A
# participant gets there with the page's `sleep 60`; in CI wait for the
# restart explicitly so the page command doesn't fail on a slow crash.
before() {
  echo "Waiting for carts pod to crash and restart..."

  for i in $(seq 1 36); do
    RESTARTS=$(kubectl get pods -n carts -l app.kubernetes.io/component=service --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
    if [ "$RESTARTS" -gt 0 ] 2>/dev/null; then
      echo "carts pod restarted after $i attempts (restarts=$RESTARTS)"
      return 0
    fi
    echo "Attempt $i: restarts=$RESTARTS, waiting..."
    sleep 10
  done

  debug
  echo "carts pod did not restart after 360s"
  exit 1
}

after() {
  LATEST_POD=$(kubectl get pods -n carts -l app.kubernetes.io/component=service --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
  LOG_OUTPUT=$(kubectl logs -n carts -p "$LATEST_POD" 2>/dev/null || true)
  if [[ "$LOG_OUTPUT" == *"Unable to load credentials"* ]]; then
    echo "Found expected credential error"
    return 0
  fi

  debug
  echo "Failed to find expected credential error in the previous carts container logs"
  exit 1
}

"$@"
