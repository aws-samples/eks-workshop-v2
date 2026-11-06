set -Eeuo pipefail

# The page creates the ui-nlb-auto Service a few seconds before it runs
# `wait-for-lb $(kubectl get service ... hostname)`. A participant reading the
# page gives the NLB time to be assigned a hostname; in CI the command runs
# immediately and wait-for-lb receives an empty argument. Wait for the hostname
# here so the test runs the page command exactly as written.

before() {
  local deadline=$((SECONDS + 180))
  local hostname=""

  while [ $SECONDS -lt $deadline ]; do
    hostname=$(kubectl get service -n ui ui-nlb-auto -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || true)

    if [ -n "$hostname" ]; then
      echo "Service ui-nlb-auto has hostname $hostname"
      return 0
    fi

    sleep 5
  done

  >&2 echo "Service ui-nlb-auto did not get a load balancer hostname after 180 seconds"
  kubectl describe service -n ui ui-nlb-auto || true
  exit 1
}

after() {
  echo "noop"
}

"$@"
