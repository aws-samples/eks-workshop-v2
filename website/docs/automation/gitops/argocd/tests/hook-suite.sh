set -e

before() {
  # Ask the capability for its own endpoint instead of expecting it in the
  # environment. At an AWS-run event the capability is pre-provisioned, so it is not
  # part of the lab's Terraform state and nothing exports it into this shell.
  #
  # serverUrl comes back with an https:// prefix and the Argo CD CLI wants a bare
  # host, so strip it here and add the scheme back only where a URL is needed.
  ARGOCD_SERVER=$(aws eks describe-capability \
    --cluster-name "$EKS_CLUSTER_NAME" \
    --capability-name argocd \
    --query 'capability.configuration.argoCd.serverUrl' \
    --output text)
  export ARGOCD_SERVER="${ARGOCD_SERVER#https://}"

  # EKS Capability does not support argocd login.
  # Generate an admin token via the API and authenticate via ARGOCD_AUTH_TOKEN.
  TOKEN=$(curl -sk -X POST \
    "https://${ARGOCD_SERVER}/api/v1/session" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":""}' \
    --grpc-web 2>/dev/null | jq -r '.token // empty')
  export ARGOCD_AUTH_TOKEN="$TOKEN"
  export ARGOCD_OPTS="--grpc-web"

  export CLUSTER_ARN=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME \
    --query 'cluster.arn' --output text)
  argocd cluster add default --aws-cluster-name $CLUSTER_ARN --yes 2>/dev/null || true
}

after() {
  prepare-environment
}

"$@"
