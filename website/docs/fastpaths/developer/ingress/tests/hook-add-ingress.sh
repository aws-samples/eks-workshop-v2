set -Eeuo pipefail

before() {
  echo "noop"
}

diagnostics() {
  local endpoint="$1"
  local last_code="$2"

  echo "Last HTTP code from http://${endpoint}/home: ${last_code}"
  echo ""
  kubectl get ingress -n ui ui-auto -o wide || true
  echo ""
  kubectl describe ingress -n ui ui-auto || true
  echo ""
  kubectl get endpointslices -n ui -l kubernetes.io/service-name=ui || true
  echo ""

  local lb_arn
  lb_arn=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?DNSName=='${endpoint}'].LoadBalancerArn" \
    --output text 2>/dev/null || true)

  if [ -n "$lb_arn" ] && [ "$lb_arn" != "None" ]; then
    local tg_arn
    for tg_arn in $(aws elbv2 describe-target-groups --load-balancer-arn "$lb_arn" \
      --query 'TargetGroups[].TargetGroupArn' --output text 2>/dev/null || true); do
      echo "Target health for $tg_arn"
      aws elbv2 describe-target-health --target-group-arn "$tg_arn" --output table 2>/dev/null || true
    done
  else
    echo "Could not find a load balancer with DNS name $endpoint"
  fi
}

after() {
  sleep 20

  local ui_endpoint
  ui_endpoint=$(kubectl get ingress -n ui ui-auto -o json | jq -r '.status.loadBalancer.ingress[0].hostname // empty')

  if [ -z "$ui_endpoint" ]; then
    >&2 echo "Failed to retrieve hostname from Ingress"
    kubectl describe ingress -n ui ui-auto || true
    exit 1
  fi

  # Same limit as lab/bin/wait-for-lb. ALB provisioning plus target
  # registration took 150-191s on some CI runs and more than 400s on others.
  local timeout_seconds=600
  local deadline=$((SECONDS + timeout_seconds))
  local code=""

  while [ $SECONDS -lt $deadline ]; do
    code=$(curl -s -o /dev/null -L --max-time 10 -w '%{http_code}' "http://${ui_endpoint}/home" || true)

    if [ "$code" == "200" ]; then
      echo "Ingress is available at http://${ui_endpoint}"
      return 0
    fi

    sleep 20
  done

  >&2 echo "Ingress did not become available after ${timeout_seconds} seconds"
  diagnostics "$ui_endpoint" "$code"
  exit 1
}

"$@"
