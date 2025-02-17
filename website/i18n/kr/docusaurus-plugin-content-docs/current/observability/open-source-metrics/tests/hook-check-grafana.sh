set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  grafana_endpoint=$(kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  export grafana_url="${grafana_endpoint}/healthz"

  EXIT_CODE=0

  timeout -s TERM 600 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${grafana_url})" != "200" ]];\
    do sleep 5;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "Grafana did not become available or return HTTP 200 for 600 seconds"
    kubectl get ingress -n grafana
    exit 1
  fi
}

"$@"
