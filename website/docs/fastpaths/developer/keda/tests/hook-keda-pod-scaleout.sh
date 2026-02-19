set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  EXIT_CODE=0
  
  timeout -s TERM 300 bash -c \
    'while [[ $(kubectl get pod -l app.kubernetes.io/instance=ui -n ui -o json | jq -r ".items | length") -lt 2 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Pods did not scale within 300 seconds"
    exit 1
  fi
}

"$@"
