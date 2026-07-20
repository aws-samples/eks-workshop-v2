set -e

before() {
  # EKS Capability does not support argocd login.
  # Generate an admin token via the API and authenticate via ARGOCD_AUTH_TOKEN.
  TOKEN=$(curl -sk -X POST \
    "https://${ARGOCD_SERVER}/api/v1/session" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":""}' \
    --grpc-web 2>/dev/null | jq -r '.token // empty')
  export ARGOCD_AUTH_TOKEN="$TOKEN"
  export ARGOCD_OPTS="--grpc-web"
  export ARGOCD_SERVER=$(echo $ARGOCD_SERVER | sed 's|^https://||')

  export CLUSTER_ARN=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME \
    --query 'cluster.arn' --output text)
  argocd cluster add default --aws-cluster-name $CLUSTER_ARN --yes 2>/dev/null || true
}

after() {
  prepare-environment
}

"$@"
