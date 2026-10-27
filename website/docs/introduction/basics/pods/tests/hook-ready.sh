set -Eeuo pipefail

before() {
  echo "Waiting for pod to be ready..."
  kubectl wait --for=condition=Ready --timeout=60s -n ui pod/ui-pod
  
  echo "Waiting for application to start listening on port 8080..."
  for i in {1..30}; do
    if kubectl exec -n ui ui-pod -- curl -s --connect-timeout 2 localhost:8080/actuator/health >/dev/null 2>&1; then
      echo "Application is ready and responding on port 8080"
      return 0
    fi
    echo "Attempt $i/30: Application not ready yet, waiting..."
    sleep 2
  done
  
  echo "Application failed to become ready within 60 seconds"
  exit 1
}

after() {
  echo "noop"
}

"$@"
