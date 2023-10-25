set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 20

  export ui_endpoint=$(kubectl -n kube-system get svc -n ui ui-nlb -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  if [ -z "$ui_endpoint" ]; then
    >&2 echo "Failed to retrieve hostname from Service"
    exit 1
  fi

  wait-for-lb ${ui_endpoint}/home
}

"$@"
