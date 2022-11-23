set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  EXIT_CODE=0

  timeout -s TERM 160 bash -c \
    'while [[ $(kubectl get nodes --selector=type=karpenter -o json | jq -r ".items | length") -gt 1 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
Karpenter nodes did not clean up
EOF
    exit 1
  fi
}

"$@"
