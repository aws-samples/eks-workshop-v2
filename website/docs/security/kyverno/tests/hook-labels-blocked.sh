set -Eeuo pipefail

before() {
  # The ui Deployment may already have CostCenter label from a previous test run
  # (applied by the ui-labeled kustomization). The require-labels policy is already
  # applied at this point, so we must temporarily delete it to strip the label,
  # then reapply it so the rollout restart is blocked as expected.
  if kubectl -n ui get deployment ui -o jsonpath='{.spec.template.metadata.labels.CostCenter}' 2>/dev/null | grep -q .; then
    kubectl delete clusterpolicy require-labels --ignore-not-found=true
    kubectl -n ui patch deployment ui --type=json \
      -p='[{"op":"remove","path":"/spec/template/metadata/labels/CostCenter"}]'
    kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/simple-policy/require-labels-policy.yaml
  fi
}

after() {
  # Verify the require-labels policy (with allowExistingViolations: false) blocks
  # a rollout restart on the ui Deployment which lacks the CostCenter label.
  # TEST_OUTPUT contains the output of the kubectl rollout restart command.
  if [[ "$TEST_OUTPUT" != *"validate.kyverno.svc-fail"* ]]; then
    >&2 echo "Expected rollout restart to be blocked by Kyverno admission webhook, but got: $TEST_OUTPUT"
    exit 1
  fi

  if [[ "$TEST_OUTPUT" != *"require-labels"* ]]; then
    >&2 echo "Expected rollout restart to be blocked by require-labels policy, but got: $TEST_OUTPUT"
    exit 1
  fi

  if [[ "$TEST_OUTPUT" != *"CostCenter"* ]]; then
    >&2 echo "Expected block reason to mention 'CostCenter' label, but got: $TEST_OUTPUT"
    exit 1
  fi
}

"$@"
