set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl -n ui get pods -o wide

  # Every ui Pod must carry the readiness gate injected by the AWS Load Balancer Controller
  pods=$(kubectl -n ui get pods -l app.kubernetes.io/name=ui -o json)

  missing=$(echo "$pods" | jq -r '.items[] | select(([.spec.readinessGates[]?.conditionType | select(startswith("target-health.elbv2.k8s.aws/"))] | length) == 0) | .metadata.name')

  if [ -n "$missing" ]; then
    >&2 echo "Pods without a target-health readiness gate: $missing"
    exit 1
  fi

  # ...and the gate must be True, since rollout status already waited for Ready
  not_healthy=$(echo "$pods" | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | select(([.status.conditions[]? | select((.type | startswith("target-health.elbv2.k8s.aws/")) and .status == "True")] | length) == 0) | .metadata.name')

  if [ -n "$not_healthy" ]; then
    >&2 echo "Pods whose target-health readiness gate is not True: $not_healthy"
    exit 1
  fi
}

"$@"
