set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 20

  export ui_endpoint=$(kubectl -n kube-system get ingress -n ui ui -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  if [ -z "$ui_endpoint" ]; then
    >&2 echo "Failed to retrieve hostname from Ingress"
    exit 1
  fi

  EXIT_CODE=0

  timeout -s TERM 400 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${ui_endpoint}/home)" != "200" ]];\
    do sleep 20;\
    done' || EXIT_CODE=$?

  echo "Timeout completed"

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Ingress did not become available after 400 seconds"
    exit 1
  fi
}

"$@"
