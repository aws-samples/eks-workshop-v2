set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 60 

  EXIT_CODE=0
  
  timeout -s TERM 60 bash -c \
    'while [[ $(kubectl get pod -l app.kubernetes.io/name=ui -n ui -o json | jq -r ".items | length") -lt 2 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "UI service did not deploy in 60 seconds"
    exit 1
  fi
}

"$@"
