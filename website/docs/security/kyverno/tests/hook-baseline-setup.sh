set -Eeuo pipefail

before() {
  # Clean up policies from previous lab sections to prevent interference.
  # require-labels blocks Deployment creation without CostCenter label on the pod
  # template, which would prevent the privileged-deploy Deployment from being
  # created in this section.
  kubectl delete clusterpolicy require-labels add-labels --ignore-not-found=true

  # Clean up any leftover privileged-deploy Deployment from previous test runs
  kubectl delete deployment privileged-deploy --ignore-not-found=true
}

after() {
  # Verify the privileged-deploy Deployment was cleaned up by the setup block
  if kubectl get deployment privileged-deploy &>/dev/null; then
    >&2 echo "Expected privileged-deploy Deployment to be deleted after setup, but it still exists"
    exit 1
  fi
}

"$@"
