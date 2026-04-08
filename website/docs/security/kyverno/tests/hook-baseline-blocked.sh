set -Eeuo pipefail

before() {
  # The doc has a plain (non-hook) bash block that creates privileged-deploy before
  # this hook block runs. Delete and recreate to ensure a clean state, since a
  # previous test run may have left it behind or the doc block already created it.
  kubectl delete deployment privileged-deploy --ignore-not-found=true
  kubectl create deployment privileged-deploy --image=public.ecr.aws/nginx/nginx
}

after() {
  # TEST_OUTPUT contains the output of the kubectl patch command from the markdown block.
  # The patch adds privileged: true to the pod template securityContext, which should
  # be blocked by the baseline-policy targeting Deployments.
  if [[ "$TEST_OUTPUT" != *"validate.kyverno.svc-fail"* ]]; then
    >&2 echo "Expected Deployment patch to be blocked by Kyverno admission webhook, but got: $TEST_OUTPUT"
    exit 1
  fi

  if [[ "$TEST_OUTPUT" != *"baseline-policy"* ]]; then
    >&2 echo "Expected Deployment patch to be blocked by baseline-policy, but got: $TEST_OUTPUT"
    exit 1
  fi

  if [[ "$TEST_OUTPUT" != *"privileged"* ]]; then
    >&2 echo "Expected block reason to mention 'privileged', but got: $TEST_OUTPUT"
    exit 1
  fi

  # Clean up
  kubectl delete deployment privileged-deploy --ignore-not-found=true
}

"$@"
