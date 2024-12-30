set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  EXIT_CODE=0

  timeout -s TERM 240 bash -c \
    'while [[ $(kubectl get nodes -l eks.amazonaws.com/nodegroup=graviton -o json | jq -r ".items | length") -lt 1 ]];\
    do sleep 10;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
Node not ready in graviton node group in 240 seconds
EOF
    exit 1
  fi

  kubectl wait --for=condition=Ready nodes --all --timeout=100s
}

"$@"
