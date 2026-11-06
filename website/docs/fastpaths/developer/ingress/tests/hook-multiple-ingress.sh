set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 60

  kubectl get ingress -A

  local catalog_endpoint
  catalog_endpoint=$(kubectl get ingress -n catalog catalog-multi -o json | jq -r '.status.loadBalancer.ingress[0].hostname // empty')

  if [ -z "$catalog_endpoint" ]; then
    >&2 echo "Failed to retrieve hostname from Ingress"
    exit 1
  fi

  # Same limit as lab/bin/wait-for-lb and hook-add-ingress.sh.
  local timeout_seconds=600
  local deadline=$((SECONDS + timeout_seconds))
  local code=""

  while [ $SECONDS -lt $deadline ]; do
    code=$(curl -s -o /dev/null -L --max-time 10 -w '%{http_code}' "http://${catalog_endpoint}/catalog/products" || true)

    if [ "$code" == "200" ]; then
      echo "Ingress is available at http://${catalog_endpoint}"
      return 0
    fi

    sleep 20
  done

  >&2 echo "Ingress did not become available after ${timeout_seconds} seconds"
  echo "Was checking http://${catalog_endpoint}/catalog/products, last HTTP code: ${code}"
  echo ""
  kubectl get ingress -A
  kubectl describe ingress -n catalog catalog-multi || true
  exit 1
}

"$@"
