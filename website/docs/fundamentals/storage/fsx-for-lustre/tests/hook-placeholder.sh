set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  export ui_endpoint=$(kubectl -n ui get service ui-nlb -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  if [ -z "$ui_endpoint" ]; then
    >&2 echo "Failed to retrieve LB hostname"
    exit 1
  fi

  if [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${ui_endpoint}/assets/img/products/placeholder.jpg)" != "200" ]]; then
    >&2 echo "Expected placeholder image not available"
    exit 1
  fi
}

"$@"
