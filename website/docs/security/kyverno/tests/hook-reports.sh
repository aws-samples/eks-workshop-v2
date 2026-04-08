set -Eeuo pipefail

before() {
  # Wait for background scan to populate policy reports
  sleep 180
}

after() {
  # Verify policy reports exist in the default namespace
  report_count=$(kubectl get policyreports -n default -o json | jq '.items | length')

  if [[ "$report_count" -lt 1 ]]; then
    >&2 echo "Expected policy reports to exist in default namespace but found none"
    exit 1
  fi

  # In Kyverno 1.13+, reports are per-resource (named by resource UID).
  # Policies now target Deployments, so reports are scoped to Deployment resources.
  # Find the report for the nginx-public Deployment (non-ECR image) which should
  # have a FAIL for restrict-image-registries.
  fail_count=$(kubectl get policyreports -n default -o json \
    | jq '[.items[] | select(.scope.kind == "Deployment") | .results[] | select(.result == "fail" and .policy == "restrict-image-registries")] | length')

  if [[ "$fail_count" -lt 1 ]]; then
    >&2 echo "Expected at least one FAIL result for restrict-image-registries policy on a Deployment in default namespace, got: $fail_count"
    exit 1
  fi

  fail_rule=$(kubectl get policyreports -n default -o json \
    | jq -r '[.items[] | select(.scope.kind == "Deployment") | .results[] | select(.result == "fail" and .policy == "restrict-image-registries")] | .[0].rule')

  if [[ "$fail_rule" != "validate-registries" ]]; then
    >&2 echo "Expected FAIL result rule to be validate-registries, got: $fail_rule"
    exit 1
  fi

  # Verify there is also a PASS result for the nginx-ecr Deployment
  pass_count=$(kubectl get policyreports -n default -o json \
    | jq '[.items[] | select(.scope.kind == "Deployment") | .results[] | select(.result == "pass" and .policy == "restrict-image-registries")] | length')

  if [[ "$pass_count" -lt 1 ]]; then
    >&2 echo "Expected at least one PASS result for restrict-image-registries policy on a Deployment in default namespace, got: $pass_count"
    exit 1
  fi

  # Clean up nginx Deployments created during the lab
  kubectl delete deployment nginx-public nginx-ecr --ignore-not-found=true
}

"$@"
