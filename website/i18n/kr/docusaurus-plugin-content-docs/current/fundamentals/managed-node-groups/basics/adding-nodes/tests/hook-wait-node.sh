set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  EXIT_CODE=0
  
  timeout -s TERM 300 bash -c \
    'while [[ $(kubectl get nodes -l eks.amazonaws.com/nodegroup=$EKS_DEFAULT_MNG_NAME -o json | jq -r ".items | length") -lt 4 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Node count did not increase to 4 as expected"
    kubectl get node
    exit 1
  fi
}

"$@"
