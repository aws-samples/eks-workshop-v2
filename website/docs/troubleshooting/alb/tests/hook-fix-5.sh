set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 120

  export ui_endpoint=$(kubectl -n kube-system get ingress -n ui ui -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  if [ -z "$ui_endpoint" ]; then
    >&2 echo "Failed to retrieve hostname from Service"
    exit 1
  fi

}

"$@"
