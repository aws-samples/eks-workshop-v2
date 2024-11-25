#!/bin/bash -x
set -e

before() {
  echo "noop"
}


after() {

NAMESPACE="gpu-operator"
RETRY_INTERVAL=60  # Wait time in seconds between retries
RETRY_LIMIT=5  # Number of retries (5 minutes)

# Check pod status
for i in $(seq 1 $RETRY_LIMIT); do
  PODS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

  for pod in $PODS; do
    STATUS=$(kubectl get pod -n "$NAMESPACE" "$pod" -o jsonpath='{.status.phase}')
    if [ "$STATUS" != "Running" ] && [ "$STATUS" != "Completed" ]; then
      echo "Pod '$pod' in namespace '$NAMESPACE' is not in the 'Running' or 'Completed' phase (current phase: $STATUS). Retrying in $RETRY_INTERVAL seconds..."
      sleep $RETRY_INTERVAL
#      break 2
    fi
  done

  echo "All pods in namespace '$NAMESPACE' are in the 'Running' or 'Completed' phase."
  exit 0
done

echo "Not all pods in namespace '$NAMESPACE' became 'Running' or 'Completed' after $RETRY_LIMIT retries ($(($RETRY_LIMIT * $RETRY_INTERVAL)) seconds)."
exit 1

}

"$@"
