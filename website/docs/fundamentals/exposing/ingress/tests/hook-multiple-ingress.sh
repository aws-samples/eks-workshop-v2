set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 60

  kubectl get ingress -A

  export catalog_endpoint=$(kubectl get ingress -n catalog catalog-multi -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  if [ -z "$catalog_endpoint" ]; then
    >&2 echo "Failed to retrieve hostname from Ingress"
    exit 1
  fi

  EXIT_CODE=0

  timeout -s TERM 400 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${catalog_endpoint}/catalogue)" != "200" ]];\
    do sleep 20;\
    done' || EXIT_CODE=$?

  echo "Timeout completed"

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Ingress did not become available after 400 seconds"
    echo "Was checking $catalog_endpoint"
    echo ""
    kubectl get ingress -A
    exit 1
  fi
}

"$@"
