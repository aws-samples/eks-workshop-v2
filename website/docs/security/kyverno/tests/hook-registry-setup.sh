set -Eeuo pipefail

before() {
  # Clean up any leftover Deployments from previous test runs to prevent AlreadyExists errors
  kubectl delete deployment nginx-public nginx-ecr nginx-blocked --ignore-not-found=true
}

after() {
  # Verify the nginx-public Deployment was created successfully
  if ! kubectl get deployment nginx-public &>/dev/null; then
    >&2 echo "Expected nginx-public Deployment to exist after setup, but it was not found"
    exit 1
  fi
}

"$@"
