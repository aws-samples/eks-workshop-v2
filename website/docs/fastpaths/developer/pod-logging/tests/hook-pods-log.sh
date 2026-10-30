set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  # Check all fluent-bit pods for "Created log stream" messages
  # Some pods may not have created streams yet depending on which node they're on
  for i in $(seq 1 6); do
    for pod in $(kubectl get pods -n amazon-cloudwatch -l app.kubernetes.io/name=aws-for-fluent-bit -o jsonpath='{.items[*].metadata.name}'); do
      LOG_OUTPUT=$(kubectl logs -n amazon-cloudwatch "$pod" 2>/dev/null || true)
      if [[ "$LOG_OUTPUT" == *"Created log stream"* ]]; then
        echo "Found 'Created log stream' in pod $pod"
        return 0
      fi
    done
    echo "Attempt $i: 'Created log stream' not found in any pod, waiting..."
    sleep 10
  done

  echo "Failed to find 'Created log stream' in any fluent-bit pod"
  exit 1
}

"$@"
