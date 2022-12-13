set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  EXIT_CODE=0

  export FIRST_NODE_NAME=$(kubectl get nodes --sort-by={metadata.name} --no-headers -l workshop-default=yes -o json | jq -r '.items[0].metadata.name')

  timeout -s TERM 260 bash -c \
    'while [[ $(kubectl get pods --field-selector spec.nodeName=$FIRST_NODE_NAME -A -o json | jq -r ".items | length") -gt 0 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
Still pods running on node $FIRST_NODE_NAME
EOF
    exit 1
  fi
}

"$@"
