set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10
  
  kubectl wait --for=condition=available --timeout=120s deployment/carts -n carts

  export endpoint=$(kubectl -n kube-system get svc -n ui ui-nlb -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  EXIT_CODE=0

  timeout -s TERM 180 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${endpoint}/home)" != "200" ]];\
    do echo "Waiting for ${endpoint}" && sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Load balancer did not become available or return HTTP 200 for 180 seconds"
    exit 1
  fi
}

"$@"
