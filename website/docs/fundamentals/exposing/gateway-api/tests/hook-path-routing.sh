set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  export gateway_endpoint=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')

  EXIT_CODE=0

  timeout -s TERM 120 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${gateway_endpoint}/catalog/products)" != "200" ]];
    do sleep 10;
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Catalog route did not become available"
    exit 1
  fi
}

"$@"
