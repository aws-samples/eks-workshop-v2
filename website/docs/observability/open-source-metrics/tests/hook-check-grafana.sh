set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  grafana_endpoint=$(kubectl get ingress -n grafana grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  grafana_url="${grafana_endpoint}/healthz"

  echo "Checking $grafana_url"

  http_status=$(curl -s -o /dev/null -w ''%{http_code}'' ${grafana_url})

  if [[ "$http_status" != "200" ]]; then
    >&2 echo "Grafana did not return HTTP 200, got $http_status"
    exit 1
  fi

  echo "Grafana got $http_status"
}

"$@"
