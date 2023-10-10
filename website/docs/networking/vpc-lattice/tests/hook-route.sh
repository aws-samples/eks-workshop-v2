set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  EXIT_CODE=0
  
  timeout --foreground -s TERM 300 bash -c \
    'while [[ $(kubectl get httproute checkoutroute -n checkout -o json | jq -r ".metadata.annotations[\"application-networking.k8s.aws/lattice-assigned-domain-name\"]") == "null" ]];\
    do sleep 5;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Lattice route was not created in 300 seconds"
    exit 1
  fi
}

"$@"