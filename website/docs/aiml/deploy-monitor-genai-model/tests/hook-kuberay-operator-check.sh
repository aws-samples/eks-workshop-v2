set -e

before() {
  echo "noop"
}


after() {
NAMESPACE=default
DEPLOYMENT_NAME="kuberay-operator"
RETRY_INTERVAL=60  # Wait time in seconds between retries
RETRY_LIMIT=2  # Number of retries (2 minutes)

# Check the deployment status
for i in $(seq 1 $RETRY_LIMIT); do
  READY_REPLICAS=$(kubectl get deployment -n "$NAMESPACE" "$DEPLOYMENT_NAME" -o jsonpath='{.status.readyReplicas}')
  DESIRED_REPLICAS=$(kubectl get deployment -n "$NAMESPACE" "$DEPLOYMENT_NAME" -o jsonpath='{.spec.replicas}')

  if [ "$READY_REPLICAS" -eq "$DESIRED_REPLICAS" ]; then
    echo "Deployment '$DEPLOYMENT_NAME' in namespace '$NAMESPACE' is successfully deployed and running."
    exit 0
  else
    echo "Deployment '$DEPLOYMENT_NAME' in namespace '$NAMESPACE' is not fully ready. Expected $DESIRED_REPLICAS replicas, but only $READY_REPLICAS are ready. Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
  fi
done

echo "Deployment '$DEPLOYMENT_NAME' in namespace '$NAMESPACE' did not become fully ready after $RETRY_LIMIT retries ($(($RETRY_LIMIT * $RETRY_INTERVAL)) seconds)."
exit 1
}

"$@"
