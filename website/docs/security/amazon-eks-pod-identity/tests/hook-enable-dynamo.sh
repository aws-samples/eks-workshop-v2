set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  kubectl rollout status deployment/carts -n carts --timeout 180s

  export endpoint=$(kubectl -n kube-system get svc -n ui ui-nlb -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  EXIT_CODE=0

  timeout -s TERM 400 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${endpoint}/home)" != "500" ]];\
    do echo "Waiting for ${endpoint}" && sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Load balancer did not become available or return HTTP 500 for 180 seconds"
    exit 1
  fi
}

"$@"
