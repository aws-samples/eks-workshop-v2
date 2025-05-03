set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 180

  export ui_endpoint=$(kubectl -n kube-system get ingress -n ui ui -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

  echo "Validating endpoint: $ui_endpoint"
  if [ -z "$ui_endpoint" ]; then
    >&2 echo "Failed to retrieve hostname from Ingress"
    exit 1
  fi

  EXIT_CODE=0

  while true; do
      response_code=$(curl -s -o /dev/null -L -w '%{http_code}' ${ui_endpoint}/home)
      echo "Current HTTP response code: ${response_code}"
      
      if [ "${response_code}" = "200" ]; then
          echo "Success! Endpoint is now available."
          exit 0
          
      fi
      
      echo "Waiting 20 seconds before next attempt..."
      EXIT_CODE=1
      sleep 20
  done
}

"$@"
