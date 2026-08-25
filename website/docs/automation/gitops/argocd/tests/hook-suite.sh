set -e

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

  # The capability authenticates only through IAM Identity Center. It has no local
  # accounts, so there is no password to post to /api/v1/session, and no EKS API
  # issues a token. A participant generates one in the Argo CD UI, which a test
  # cannot do, so mint one by driving the same sign-in headlessly.
  #
  # Deliberately not tolerant of failure: without a token every argocd command below
  # would run unauthenticated and the suite would report confusing downstream errors
  # instead of the real cause.
  ARGOCD_AUTH_TOKEN=$(python3 "$hook_dir/argocd-token.py" --server "$ARGOCD_SERVER")
  export ARGOCD_AUTH_TOKEN
  export ARGOCD_OPTS="--grpc-web"

  export CLUSTER_ARN=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME \
    --query 'cluster.arn' --output text)
  argocd cluster add default --aws-cluster-name $CLUSTER_ARN --yes 2>/dev/null || true
}

after() {
  prepare-environment
}

"$@"
