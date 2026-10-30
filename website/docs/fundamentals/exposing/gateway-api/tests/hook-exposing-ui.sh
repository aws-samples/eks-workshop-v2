set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 20

  export gateway_endpoint=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')

  if [ -z "$gateway_endpoint" ]; then
    >&2 echo "Failed to retrieve address from Gateway"
    exit 1
  fi

  EXIT_CODE=0

  timeout -s TERM 400 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${gateway_endpoint}/home)" != "200" ]];
    do sleep 20;
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Gateway ALB did not become available after 400 seconds"
    exit 1
  fi
}

"$@"
